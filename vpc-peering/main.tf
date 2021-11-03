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
  cidr_block  = "10.0.0.0/16"
  tags = {
    Name = "vpc1"
  }
}
resource "aws_vpc" "vpc2" {
  cidr_block  = "172.31.0.0/16"
  tags = {
    Name = "vpc2"
  }
}

# Configure a subnet in each VPC
resource "aws_subnet" "cidr1" {
  depends_on        = [aws_vpc.vpc1]
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "vpc-peering-demo-cidr1"
  }
}
resource "aws_subnet" "cidr2" {
  depends_on        = [aws_vpc.vpc2]
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = "172.31.0.0/24"
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
    from_port   = -1
    to_port     = -1
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
    cidr_blocks = ["10.0.0.0/24"]
  }
  ingress {
    description = "ICMP PING from Anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/24"]
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

# Configuring the local SSH key
resource "aws_key_pair" "ubuntu" {
  key_name   = "ubuntu"
  public_key = file("key.pub")
}

# Configuring EC2 Instance for VM1 in VPC1
resource "aws_instance" "vm1" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  key_name      = aws_key_pair.ubuntu.key_name
  subnet_id     = aws_subnet.cidr1.id
  private_ip    = "10.0.0.4"
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.SG1_allow_ssh_ping.id ]
  tags = {
    Name = "vm1"
  }
}
# Configure an IGW
resource "aws_internet_gateway" "igw" {
  depends_on = [
    aws_vpc.vpc1,
    aws_subnet.cidr1
  ]
  vpc_id  = aws_vpc.vpc1.id
  tags = {
    Name = "vpc1-igw"
  }
}

# Configure a VPC Peering between VPC1 and VPC2
resource "aws_vpc_peering_connection" "vpcp" {
  vpc_id        = aws_vpc.vpc1.id
  peer_vpc_id   = aws_vpc.vpc2.id
  auto_accept   = true

  tags = {
    Name = "VPC Peering between VPC1 and VPC2"
  }
}

# Configure a default route
resource "aws_route_table" "rt1" {
  depends_on = [
    aws_vpc.vpc1,
    aws_internet_gateway.igw
  ]
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block = "172.31.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpcp.id
  }
  tags = {
    Name = "VPC1 default route 0/0 + route to VPC2"
  }
}

# Associate the default route with the cidr1 subnet
resource "aws_route_table_association" "rt1-cidr1" {
  subnet_id      = aws_subnet.cidr1.id
  route_table_id = aws_route_table.rt1.id
}


# Configuring VM2 in VPC2
resource "aws_instance" "vm2" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  key_name      = aws_key_pair.ubuntu.key_name
  subnet_id     = aws_subnet.cidr2.id
  private_ip    = "172.31.0.8"
  vpc_security_group_ids = [ aws_security_group.SG2_allow_ssh_ping.id ]
  tags = {
    Name = "vm2"
  }
  *_block_device {
    encrypted = true
  }
}

# Configure a route from VPC2 to VPC1
resource "aws_route_table" "rt2" {
  depends_on = [
    aws_vpc.vpc2,
    aws_internet_gateway.igw
  ]
  vpc_id = aws_vpc.vpc2.id
  route {
    cidr_block = "10.0.0.0/24"
    gateway_id = aws_vpc_peering_connection.vpcp.id
  }
  tags = {
    Name = "VPC2 route to VPC1"
  }
}

# Associate the default route with the cidr1 subnet
resource "aws_route_table_association" "rt2-cidr2" {
  subnet_id      = aws_subnet.cidr2.id
  route_table_id = aws_route_table.rt2.id
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