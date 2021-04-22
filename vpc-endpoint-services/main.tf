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

# Configure VPC-A and VPC-B
resource "aws_vpc" "VPC-A" {
  cidr_block = var.VPC-A-CIDR
  tags = {
    Name = "VPC-A"
  }
}
resource "aws_vpc" "VPC-B" {
  cidr_block = var.VPC-B-CIDR
  tags = {
    Name = "VPC-B"
  }
}

# Configure 2x subnets in VPC-A
resource "aws_subnet" "SUBNET-AZa-PUBLIC" {
  depends_on        = [aws_vpc.VPC-A]
  vpc_id            = aws_vpc.VPC-A.id
  cidr_block        = var.SUBNET-AZa-PUBLIC
  availability_zone = var.AZa
  tags = {
    Name = "SUBNET-AZa-PUBLIC"
  }
}
resource "aws_subnet" "SUBNET-AZa-PRIVATE" {
  depends_on        = [aws_vpc.VPC-A]
  vpc_id            = aws_vpc.VPC-A.id
  cidr_block        = var.SUBNET-AZa-PRIVATE
  availability_zone = var.AZa
  tags = {
    Name = "SUBNET-AZa-PRIVATE"
  }
}
# Configure the VPC-A internet gateway
resource "aws_internet_gateway" "VPC-A-IGW" {
  vpc_id = aws_vpc.VPC-A.id
  tags = {
    Name = "VPC-A-IGW"
  }
}

# Configure 2x subnets in VPC-B
resource "aws_subnet" "SUBNET-AZb-PRIVATE" {
  depends_on        = [aws_vpc.VPC-B]
  vpc_id            = aws_vpc.VPC-B.id
  cidr_block        = var.SUBNET-AZb-PRIVATE
  availability_zone = var.AZb
  tags = {
    Name = "SUBNET-AZb-PRIVATE"
  }
}
resource "aws_subnet" "SUBNET-AZc-PRIVATE" {
  depends_on        = [aws_vpc.VPC-B]
  vpc_id            = aws_vpc.VPC-B.id
  cidr_block        = var.SUBNET-AZc-PRIVATE
  availability_zone = var.AZc
  tags = {
    Name = "SUBNET-AZc-PRIVATE"
  }
}

# Configure a default route for the PUBLIC subnets toward the IGW
resource "aws_route_table" "PUBLIC-RT" {
  depends_on = [
    aws_vpc.VPC-A,
    aws_internet_gateway.VPC-A-IGW
  ]
  vpc_id = aws_vpc.VPC-A.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC-A-IGW.id
  }
  tags = {
    Name = "PUBLIC-RT"
  }
}

# Associate the default route with the cidr1 subnet
resource "aws_route_table_association" "rt0-SUBNET-AZa-PUBLIC" {
  subnet_id      = aws_subnet.SUBNET-AZa-PUBLIC.id
  route_table_id = aws_route_table.PUBLIC-RT.id
}

# Configure a Security Group for the Public subnet in VPC-A
resource "aws_security_group" "PUBLIC-SG-A" {
  name        = "PUBLIC-SG-A"
  description = "Security Group for the Public subnet in VPC-A"
  vpc_id      = aws_vpc.VPC-A.id

  ingress {
    description = "Remote Admin from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP PING from the internet"
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
    Name = "PUBLIC-SG-A"
  }
}

# Configure a Security Group for the Private subnet in VPC-A
resource "aws_security_group" "PRIVATE-SG-A" {
  name        = "PRIVATE-SG-A"
  description = "Security Group for the Private subnet in VPC-A"
  vpc_id      = aws_vpc.VPC-A.id

  ingress {
    description = "Remote Admin from the Public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ var.SUBNET-AZa-PUBLIC ]
  }
  ingress {
    description = "ICMP PING from the Public subnet"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [ var.SUBNET-AZa-PUBLIC ]
  }
  egress {
    description = "Allow everything else"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "PRIVATE-SG-A"
  }
}

# Configure a Security Group for the Private subnet in VPC-B
resource "aws_security_group" "PRIVATE-SG-B" {
  name        = "PRIVATE-SG-B"
  description = "Security Group for the Private subnet in VPC-B"
  vpc_id      = aws_vpc.VPC-B.id

  ingress {
    description = "Remote Admin from the Public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ var.SUBNET-AZa-PRIVATE ]
  }
  ingress {
    description = "ICMP PING from the Public subnet"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [ var.SUBNET-AZa-PRIVATE ]
  }
  egress {
    description = "Allow everything else"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "PRIVATE-SG-B"
  }
}

# Configuring the local SSH key
resource "aws_key_pair" "KEY" {
  key_name   = "KEY"
  public_key = file("key.pub")
}

# Configuring an EC2 Instance for the Jump Box in VPC-A's Public subnet
resource "aws_instance" "PUBLIC-JUMP-BOX" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.SUBNET-AZa-PUBLIC.id
  private_ip                  = var.PUBLIC-JUMP-BOX-IP
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.PUBLIC-SG-A.id]
  tags = {
    "Name" = "PUBLIC-JUMP-BOX"
  }
}
# Configuring an EC2 Instance for the Private Consumer Box in VPC-A's Private subnet
resource "aws_instance" "PRIVATE-CONSUMER-BOX" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.SUBNET-AZa-PRIVATE.id
  private_ip                  = var.PRIVATE-CONSUMER-BOX-IP
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.PRIVATE-SG-A.id]
  tags = {
    "Name" = "PRIVATE-CONSUMER-BOX"
  }
}

# Configuring 2x EC2 Instances for the Private Provider Boxes in VPC-B's Private subnet
resource "aws_instance" "PRIVATE-PROVIDER-BOX1" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.SUBNET-AZb-PRIVATE.id
  private_ip                  = var.PRIVATE-PROVIDER-BOX1-IP
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.PRIVATE-SG-B.id]
  tags = {
    "Name" = "PRIVATE-PROVIDER-BOX1"
  }
}
resource "aws_instance" "PRIVATE-PROVIDER-BOX2" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.SUBNET-AZc-PRIVATE.id
  private_ip                  = var.PRIVATE-PROVIDER-BOX2-IP
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.PRIVATE-SG-B.id]
  tags = {
    "Name" = "PRIVATE-PROVIDER-BOX2"
  }
}

# Getting the AWS AMI ID for the lastest version of Ubuntu 16.04 server
data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Configuring the Network Load Balancer in VPC-B towards AZb and AZc subnets
resource "aws_lb" "VPC-B-NLB" {
  name               = "VPC-B-NLB"
  internal           = true
  load_balancer_type = "network"
  subnets            = [ aws_subnet.SUBNET-AZb-PRIVATE.id, aws_subnet.SUBNET-AZc-PRIVATE.id ]
  enable_cross_zone_load_balancing = true
  enable_deletion_protection = true
  tags = {
    Environment = "Provider"
  }
}
resource "aws_lb_target_group" "VPC-B-TARGETS" {
  name     = "VPC-B-TARGETS"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.VPC-B.id
}

resource "aws_vpc_endpoint_service" "VPCA-ES" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.VPC-B-NLB.arn]
}