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
  region = var.AWS-REGION
}

# Configure VPC1
resource "aws_vpc" "VPC1" {
  cidr_block = var.VPC1-CIDR
  tags = {
    Name = "VPC1"
  }
}

# Configure 2x subnets in VPC1
resource "aws_subnet" "PUBLIC1" {
  depends_on        = [aws_vpc.VPC1]
  vpc_id            = aws_vpc.VPC1.id
  cidr_block        = var.SUBNET-PUBLIC1
  availability_zone = var.AWS-AZ1
  tags = {
    Name = "PUBLIC1"
  }
}
resource "aws_subnet" "PUBLIC2" {
  depends_on        = [aws_vpc.VPC1]
  vpc_id            = aws_vpc.VPC1.id
  cidr_block        = var.SUBNET-PUBLIC2
  availability_zone = var.AWS-AZ2
  tags = {
    Name = "PUBLIC2"
  }
}
# Configure an internet gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.VPC1.id
  tags = {
    Name = "VPC1-IGW"
  }
}

# Configure a default route for the PUBLIC subnets toward the IGW
resource "aws_route_table" "PUBLIC-RT" {
  depends_on = [
    aws_vpc.VPC1,
    aws_internet_gateway.IGW
  ]
  vpc_id = aws_vpc.VPC1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name = "PUBLIC-RT"
  }
}


# Associate the default route with the cidr1 subnet
resource "aws_route_table_association" "rt0-PUBLIC1" {
  subnet_id      = aws_subnet.PUBLIC1.id
  route_table_id = aws_route_table.PUBLIC-RT.id
}
resource "aws_route_table_association" "rt0-PUBLIC2" {
  subnet_id      = aws_subnet.PUBLIC2.id
  route_table_id = aws_route_table.PUBLIC-RT.id
}


# Configure a Security Groups to allow HTTP, SSH and ICMP PINGs
resource "aws_security_group" "PUBLIC-SG" {
  name        = "PUBLIC-SG"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.VPC1.id

  ingress {
    description = "Remote Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP PING from Anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow everything else"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "PUBLIC-SG"
  }
}

# Configuring the local SSH key
resource "aws_key_pair" "KEY" {
  key_name   = "KEY"
  public_key = file("key.pub")
}

# Configuring 2x EC2 Instances for the web servers in the Public subnet
resource "aws_instance" "web1" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.PUBLIC1.id
  private_ip                  = var.EC2-IP1
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.PUBLIC-SG.id]
  tags = {
    "Name" = "web1"
  }
}
resource "aws_instance" "web2" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.PUBLIC2.id
  private_ip                  = var.EC2-IP2
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.PUBLIC-SG.id]
  tags = {
    "Name" = "web2"
  }
  *_block_device {
    encrypted = true
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
