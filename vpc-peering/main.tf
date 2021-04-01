# Configure the Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Configure two VPCs
resource "aws_vpc" "vpc1" {
  cidr_block  = "10.1.0.0/16"
  tags = {
    Name = "vpc1"
  }
}
resource "aws_vpc" "vpc2" {
  cidr_block  = "10.2.0.0/16"
  tags = {
    Name = "vpc2"
  }
}

# Configure a subnet in each VPC
resource "aws_subnet" "cidr1" {
  depends_on        = [aws_vpc.vpc1]
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "vpc-peering-demo-cidr1"
  }
}
resource "aws_subnet" "cidr2" {
  depends_on        = [aws_vpc.vpc2]
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "vpc-peering-demo-cidr2"
  }
}

# Configure Security Groups to allow SSH and ICMP PINGs
resource "aws_security_group" "SG1_allow_ssh_ping" {
  name        = "SG1_allow_ssh_ping"
  description = "Allow SSH and PING inbound traffic"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "SSH from Anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP PING from Anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG1_allow_ssh_ping"
  }
}

resource "aws_security_group" "SG2_allow_ssh_ping" {
  name        = "SG2_allow_ssh_ping"
  description = "Allow SSH and PING inbound traffic"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    description = "SSH from Anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP PING from Anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG2_allow_ssh_ping"
  }
}

# Configuring VM1 in VPC1
resource "aws_instance" "vm1" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.cidr1.id
  private_ip    = "10.1.1.11"
  associate_public_ip_address = true
  tags = {
    Name = "vm1"
  }
}

# Configuring VM2 in VPC2
resource "aws_instance" "vm2" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.cidr2.id
  private_ip    = "10.2.2.22"
  tags = {
    Name = "vm2"
  }
}

# Getting the AWS AMI ID for the lastest version of Ubuntu 16.04 server
data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}