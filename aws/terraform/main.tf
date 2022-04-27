terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "laboratorio" {
  ami                         = data.aws_ami.ubuntu.id
  count                       = 2
  instance_type               = "t2.micro"
  key_name                    = "laboratorio" # Insira o nome da chave criada antes.
  subnet_id                   = var.lab_subnet_public_id
  vpc_security_group_ids      = [aws_security_group.permitir_ssh_http.id]
  associate_public_ip_address = true
  availability_zone           = "us-east-1d"
  
  ebs_block_device {
    device_name = "/dev/sda1"
    snapshot_id = null
    volume_type = "standard"
    delete_on_termination = true
    volume_size = 20
    tags = {
      VolumeName = "ec2-${count.index + 1}"
    }
  }

  tags = {
    Name = "EC2-LAB-${count.index + 1}" # Insira o nome da instância de sua preferência.
  }
}

variable "lab_vpc_id" {
  default = "vpc-xxxxxxxx" # Copie essa informação da VPC Default no seu perfil na AWS.
}

variable "lab_subnet_public_id" {
  default = "subnet-xxxxxxxx" # Copie essa informação da Subnet Default no seu perfil na AWS.
}


resource "aws_security_group" "permitir_ssh_http_service" {
  name        = "permitir_ssh"
  description = "Permite SSH HTTP HTTPS e Ports Zabbix nas instancias EC2"
  vpc_id      = var.lab_vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Substituir pelo seu IP público ex: 177.77.77.77/32
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Substituir pelo seu IP público ex: 177.77.77.77/32
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Substituir pelo seu IP público ex: 177.77.77.77/32
  }
  
  ingress {
    description = "Service"
    from_port   = 10051
    to_port     = 10051
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Substituir pelo range IP da sua Subnet da AWS
  }

  ingress {
    description = "Service"
    from_port   = 10050
    to_port     = 10050
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Substituir pelo range IP da sua Subnet da AWS
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Substituir pelo seu IP público ex: 177.77.77.77/32
  }

  tags = {
    Name = "Liberar_Portas_Laboratio"
  }
  
  output "instance_ip_addr" {
  value       = aws_instance.laboratorio.public_ip
  description = "The private IP address of the main server instance."
  }
  
}
