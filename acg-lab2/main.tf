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

# Configure VPCE-DEMO
resource "aws_vpc" "VPCE-DEMO" {
  cidr_block = var.VPCE-DEMO-CIDR
  tags = {
    Name = "VPCE-DEMO"
  }
}

# Configure 4x subnets in VPCE-DEMO
resource "aws_subnet" "PUBLIC" {
  depends_on        = [aws_vpc.VPCE-DEMO]
  vpc_id            = aws_vpc.VPCE-DEMO.id
  cidr_block        = var.SUBNET-PUBLIC
  availability_zone = var.AWS-AZ1
  tags = {
    Name = "PUBLIC"
  }
}
resource "aws_subnet" "PRIVATE" {
  depends_on        = [aws_vpc.VPCE-DEMO]
  vpc_id            = aws_vpc.VPCE-DEMO.id
  cidr_block        = var.SUBNET-PRIVATE
  availability_zone = var.AWS-AZ1
  tags = {
    Name = "PRIVATE"
  }
}

# Configure an internet gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.VPCE-DEMO.id
  tags = {
    Name = "VPCE-DEMO-IGW"
  }
}

# Configure a default route for the PUBLIC subnets toward the IGW
resource "aws_route_table" "PUBLIC-RT" {
  depends_on = [
    aws_vpc.VPCE-DEMO,
    aws_internet_gateway.IGW
  ]
  vpc_id = aws_vpc.VPCE-DEMO.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name = "PUBLIC-RT"
  }
}

# Associate the default route with the PUBLIC subnet
resource "aws_route_table_association" "rt0-PUBLIC" {
  subnet_id      = aws_subnet.PUBLIC.id
  route_table_id = aws_route_table.PUBLIC-RT.id
}

# Configure a Security Groups to allow HTTP, SSH and ICMP PINGs
resource "aws_security_group" "PUBLIC-SG" {
  name        = "PUBLIC-SG"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.VPCE-DEMO.id

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
    Name = "PUBLIC-SG"
  }
}

# Configuring the cloud-init script
data "template_file" "cloud-init-config" {
  template = file("cloud-init-ec2.yaml")
}

# Configuring the local SSH key
resource "aws_key_pair" "KEY" {
  key_name   = "KEY"
  public_key = file("ssh/key.pub")
}

# Configuring EC2 Instance for the PUBLIC-EC2 Host in the Public subnet
resource "aws_instance" "PUBLIC-EC2" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.PUBLIC.id
  private_ip                  = var.EC2-PUBLIC-IP
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.PUBLIC-SG.id]
  user_data                   = data.template_file.cloud-init-config.rendered
  tags = {
    "Name" = "PUBLIC-EC2"
  }
}

# Getting the AWS AMI ID for the lastest version of Ubuntu 16.04 server
data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    #values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]"
    #values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Configure a Security Group for PRIVATE-SG
resource "aws_security_group" "PRIVATE-SG" {
  name        = "PRIVATE-SG"
  description = "Allow traffic to the PRIVATE subnet"
  vpc_id      = aws_vpc.VPCE-DEMO.id

  ingress {
    description = "SSH from PUBLIC-EC2 Host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }
  ingress {
    description = "ICMP PING from PUBLIC-EC2 Host"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/24"]
  }
  egress {
    description = "Allow everything else"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "PRIVATE-SG"
  }
}

# Configuring EC2 Instance in the PRIVATE Subnet
resource "aws_instance" "PRIVATE-EC2" {
  ami                         = data.aws_ami.latest-ubuntu.id
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.KEY.key_name
  subnet_id                   = aws_subnet.PRIVATE.id
  private_ip                  = var.EC2-PRIVATE-IP
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.PRIVATE-SG.id]
  user_data                   = data.template_file.cloud-init-config.rendered
  tags = {
    "Name" = "PRIVATE-EC2"
  }
}

# Configure an S3 bucket object
resource "aws_s3_bucket" "BUCKET" {
  tags = {
    "Name" = "BUCKET"
  }
}

resource "aws_s3_bucket_object" "OBJECT" {
  bucket = aws_s3_bucket.BUCKET.id
  key    = "acg-lab2.png"
  source = "acg-lab2.png"
  tags = {
    "Name" = "OBJECT"
  }
}


# Configure AWS Flow Log with CoudWatch logging
resource "aws_flow_log" "ACG-LAB2" {
  iam_role_arn    = aws_iam_role.LAB2-ROLE.arn
  log_destination = aws_cloudwatch_log_group.ACG-LAB2.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.VPCE-DEMO.id
}

resource "aws_cloudwatch_log_group" "ACG-LAB2" {
  name = "ACG-LAB2"
}

resource "aws_iam_role" "LAB2-ROLE" {
  name = "LAB2-ROLE"

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

resource "aws_iam_role_policy" "ACG-LAB2-POLICY" {
  name = "ACG-LAB2-POLICY"
  role = aws_iam_role.LAB2-ROLE.id

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