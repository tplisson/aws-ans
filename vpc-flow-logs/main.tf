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
  region = var.aws_region
}

# Configure VPC1
resource "aws_vpc" "vpc1" {
  cidr_block  = var.vpc_cidr
  tags = {
    Name = "vpc1"
  }
}

# Configure a subnet in VPC1
resource "aws_subnet" "cidr1" {
  depends_on        = [aws_vpc.vpc1]
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.aws_az1
  tags = {
    Name = "cidr1"
  }
}

# Configure a Security Groups to allow HTTP, SSH and ICMP PINGs
resource "aws_security_group" "sg1" {
  name        = "sg1"
  description = "Allow HTTP/s, SSH and PING traffic"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "HTTP from Anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP:8000 from Anywhere"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
    Name = "SG1"
  }
}

# Configuring the local SSH key
resource "aws_key_pair" "ubuntu" {
  key_name   = "ubuntu"
  public_key = file("key.pub")
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
  tags = {
    Name = "VPC1-default-route-to-IGW"
  }
}

# Associate the default route with the cidr1 subnet
resource "aws_route_table_association" "rt1-cidr1" {
  subnet_id      = aws_subnet.cidr1.id
  route_table_id = aws_route_table.rt1.id
}

data "template_file" "server-config" {
  template = file("scripts/add-ssh-web-app.yaml")
}

# Configuring EC2 Instance for webserver in VPC1
resource "aws_instance" "webserver" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  key_name      = aws_key_pair.ubuntu.key_name
  subnet_id     = aws_subnet.cidr1.id
  private_ip    = var.ec2_ip1
  associate_public_ip_address = true
  vpc_security_group_ids  = [ aws_security_group.sg1.id ]
  user_data               = data.template_file.server-config.rendered 
  tags = {
    "Name"      = "Webserver"
    "Terraform" = "true"
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

# Configure CoudWatch Logging
resource "aws_flow_log" "example" {
  iam_role_arn    = aws_iam_role.example.arn
  log_destination = aws_cloudwatch_log_group.example.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc1.id
}

resource "aws_cloudwatch_log_group" "example" {
  name = "example"
}

resource "aws_iam_role" "example" {
  name = "example"

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

resource "aws_iam_role_policy" "example" {
  name = "example"
  role = aws_iam_role.example.id

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