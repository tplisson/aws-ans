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
  region     = "us-east-1"
}

# Configure a VPC in the 10.10/16 CIDR block
resource "aws_vpc" "main" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "tom03"
  }
}

# Configure 3 subnets
resource "aws_subnet" "cidr1" {
  depends_on = [aws_vpc.main]
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "tom03-cidr-1"
  }
}
resource "aws_subnet" "cidr2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "tom03-cidr-2"
  }
}
resource "aws_subnet" "cidr3" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.10.3.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "tom03-cidr-3"
  }
}

# Configure an IGW
resource "aws_internet_gateway" "igw1" {
  depends_on = [
    aws_vpc.main,
    aws_subnet.cidr1,
    aws_subnet.cidr2,
    aws_subnet.cidr3
  ]
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "tom03-igw1"
  }
}

# Configure default routes
resource "aws_route_table" "rt1" {
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.igw1
  ]
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
  tags = {
    Name = "tom03-rt-igw1-0/0"
  }
}

# Configre an Elastic IP for the NAT Gateway
resource "aws_eip" "nat1" {
  vpc = true
  tags = {
    Name = "tom03-nat-gw-eip-1"
  }
}

# Configure a NAT Gateway
resource "aws_nat_gateway" "natgw1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.cidr1.id
  depends_on    = [aws_internet_gateway.igw1]
  tags  = {
    Name = "tom03-nat-gw1"
  }
}

# Configuring a Route Table for the NAT Gateway
resource "aws_route_table" "rt-nat1" {
  depends_on = [
    aws_nat_gateway.natgw1
  ]
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw1.id
  }
  tags = {
    Name = "tom03-rt-nat1-0/0"
  }
}

# Creating an Route Table Association of the NAT Gateway route table with the Private Subnet!
resource "aws_route_table_association" "natgw1-assoc" {
  depends_on = [
    aws_route_table.rt-nat1
  ]
#  Private Subnet ID for adding this route table to the DHCP server of Private subnet!
  subnet_id      = aws_subnet.cidr1.id
# Route Table ID
  route_table_id = aws_route_table.rt-nat1.id
}


# Configure an EC2 instance for VM1
resource "aws_instance" "vm1" {
  depends_on = [ aws_subnet.cidr1 ]
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.cidr1.id
  private_ip = "10.10.1.10"
  tags = {
    Name = "tom03-vm1"
  }
}

# Configure an EC2 instance for VM2
resource "aws_instance" "vm2" {
  depends_on = [ aws_subnet.cidr2 ]
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.micro"
  subnet_id 	= aws_subnet.cidr2.id
  private_ip 	= "10.10.2.10"
  tags = {
    Name = "tom03-vm2"
  }
}

# Configure an EC2 instance for VM3
resource "aws_instance" "vm3" {
  depends_on = [ aws_subnet.cidr3 ]
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.micro"
  subnet_id 	= aws_subnet.cidr3.id
  private_ip 	= "10.10.3.10"
  tags = {
    Name = "tom03-vm3"
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
