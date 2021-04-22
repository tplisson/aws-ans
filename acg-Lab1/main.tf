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

# Configure 4x subnets in VPC1
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
resource "aws_subnet" "PRIVATE3" {
  depends_on        = [aws_vpc.VPC1]
  vpc_id            = aws_vpc.VPC1.id
  cidr_block        = var.SUBNET-PRIVATE3
  availability_zone = var.AWS-AZ1
  tags = {
    Name = "PRIVATE3"
  }
}
resource "aws_subnet" "PRIVATE4" {
  depends_on        = [aws_vpc.VPC1]
  vpc_id            = aws_vpc.VPC1.id
  cidr_block        = var.SUBNET-PRIVATE4
  availability_zone = var.AWS-AZ2
  tags = {
    Name = "PRIVATE4"
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

# Configre an Elastic IP for the NAT Gateway
resource "aws_eip" "EIP1" {
  vpc = true
  tags = {
    Name = "EIP1"
  }
}

# Configure a NAT Gateway
resource "aws_nat_gateway" "NATGW" {
  depends_on    = [aws_internet_gateway.IGW]
  allocation_id = aws_eip.EIP1.id
  subnet_id     = aws_subnet.PUBLIC2.id
  tags = {
    Name = "NATGW"
  }
}

# Configure a default route for the PRIVATE subnets toward the NAT GW
resource "aws_route_table" "PRIVATE-RT" {
  depends_on = [
    aws_vpc.VPC1,
    aws_internet_gateway.IGW
  ]
  vpc_id = aws_vpc.VPC1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NATGW.id
  }
  tags = {
    Name = "PRIVATE-RT"
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
resource "aws_route_table_association" "rt0-PRIVATE3" {
  subnet_id      = aws_subnet.PRIVATE3.id
  route_table_id = aws_route_table.PRIVATE-RT.id
}
resource "aws_route_table_association" "rt0-PRIVATE4" {
  subnet_id      = aws_subnet.PRIVATE4.id
  route_table_id = aws_route_table.PRIVATE-RT.id
}

# Configure a NACL for subnet PUBLIC1
# resource "aws_network_acl" "PUBLIC1" {
#   vpc_id      = aws_vpc.VPC1.id
#   subnet_ids  = [ aws_subnet.PUBLIC1.id ]

#   ingress {
#     rule_no    = 110
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "192.168.0.10/32"
#     from_port  = 22
#     to_port    = 22
#   }
#   ingress {
#     rule_no    = 110
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "192.168.0.10/32"
#     from_port  = 22
#     to_port    = 22
#   }
#   egress {
#     rule_no    = 110
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "192.168.0.10/32"
#     from_port  = 1024
#     to_port    = 65535
#   }

#   tags = {
#     Name = "PUBLIC1"
#   }
# }

# Configure a Security Groups to allow HTTP, SSH and ICMP PINGs
resource "aws_security_group" "BASTION-SG" {
  name        = "BASTION-SG"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.VPC1.id

  ingress {
    description = "RemoteAdmin"
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
    description = "SSH to AppServers"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"]
  }
  egress {
    description = "Allow everything else"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "BASTION-SG"
  }
}

# Configuring the local SSH key
resource "aws_key_pair" "KEY" {
  key_name   = "KEY"
  public_key = file("key.pub")
}

# Configuring EC2 Instance for the Bastion Host in the Public subnet
resource "aws_instance" "BASTION" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.PUBLIC1.id
  private_ip                  = var.EC2-IP1
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.BASTION-SG.id]
  tags = {
    "Name" = "BASTION"
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

# Configure a Security Group for PRIVATE34-SG
resource "aws_security_group" "PRIVATE34-SG" {
  name        = "PRIVATE34-SG"
  description = "Allow traffic to subnets PRIVATE3 and 4"
  vpc_id      = aws_vpc.VPC1.id

  ingress {
    description = "SSH from Bastion Host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/26"]
  }
  ingress {
    description = "ICMP PING from Bastion Host"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["192.168.0.0/26"]
  }
  egress {
    description = "Allow all HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "PRIVATE34-SG"
  }
}

# Configuring EC2 Instance in the PRIVATE3 Subnet
resource "aws_instance" "APP-SERVER1" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.PRIVATE3.id
  private_ip                  = var.EC2-IP2
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.PRIVATE34-SG.id]
  tags = {
    "Name" = "APP-SERVER1"
  }
}

# Configuring EC2 Instance in the PRIVATE4 Subnet
resource "aws_instance" "APP-SERVER2" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.PRIVATE4.id
  private_ip                  = var.EC2-IP3
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.PRIVATE34-SG.id]
  tags = {
    "Name" = "APP-SERVER2"
  }
}


# Configure AWS Flow Log with CoudWatch logging
resource "aws_flow_log" "ACG-LAB1" {
  iam_role_arn    = aws_iam_role.LAB1-ROLE.arn
  log_destination = aws_cloudwatch_log_group.ACG-LAB1.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.VPC1.id
}

resource "aws_cloudwatch_log_group" "ACG-LAB1" {
  name = "ACG-LAB1"
}

resource "aws_iam_role" "LAB1-ROLE" {
  name = "LAB1-ROLE"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ACG-LAB1-POLICY" {
  name = "ACG-LAB1-POLICY"
  role = aws_iam_role.LAB1-ROLE.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}