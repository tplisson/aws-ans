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

# Configure a VPC in the 10.0/16 CIDR block
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "nat-gw-demo"
  }
}

# Configure 2 subnets
resource "aws_subnet" "cidr1" {
  depends_on        = [aws_vpc.main]
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "nat-gw-demo-cidr-1"
  }
}
resource "aws_subnet" "cidr2" {
  depends_on        = [aws_vpc.main]
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "nat-gw-demo-cidr-2"
  }
}

# Configure an IGW
resource "aws_internet_gateway" "igw" {
  depends_on = [
    aws_vpc.main,
    aws_subnet.cidr1,
    aws_subnet.cidr2
  ]
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "nat-gw-demo-igw"
  }
}

# Configure default routes
resource "aws_route_table" "rt-igw" {
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.igw
  ]
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "nat-gw-demo-rt-igw-0/0"
  }
}

# Configre an Elastic IP for the NAT Gateway
resource "aws_eip" "eip1" {
  vpc = true
  tags = {
    Name = "nat-gw-demo-eip1"
  }
}

# Configure a NAT Gateway
resource "aws_nat_gateway" "natgw" {
  depends_on    = [aws_internet_gateway.igw]
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.cidr1.id
  tags = {
    Name = "nat-gw-demo-nat-gw"
  }
}

# Configuring a Route Table for the NAT Gateway
resource "aws_route_table" "rt-nat" {
  depends_on = [
    aws_nat_gateway.natgw
  ]
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "nat-gw-demo-rt-nat-0/0"
  }
}

# Creating an Route Table Association of the NAT Gateway route table with the Private Subnet!
resource "aws_route_table_association" "natgw-assoc" {
  depends_on = [
    aws_route_table.rt-nat
  ]
  #  Private Subnet ID for adding this route table to the DHCP server of Private subnet!
  subnet_id = aws_subnet.cidr1.id
  # Route Table ID
  route_table_id = aws_route_table.rt-nat.id
}

# Configuring an EC2 instance for a web server in the public subnet
resource "aws_instance" "web" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.cidr1.id
  private_ip    = "10.0.0.10"
  associate_public_ip_address = true

  tags = {
    Name = "nat-gw-demo-ec2-web"
  }
  ebs_optimized = true
}

# Configuring 3x EC2 instances for DB servers in the private subnet
variable "instance_ips" {
  default = {
    "0" = "10.0.1.11"
    "1" = "10.0.1.12"
    "2" = "10.0.1.13"
  }
}
resource "aws_instance" "db" {
  count         = "3"
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.cidr2.id
  private_ip    = lookup(var.instance_ips, count.index)

  tags = {
    Name = "nat-gw-demo-ec2-db${count.index + 1}"
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