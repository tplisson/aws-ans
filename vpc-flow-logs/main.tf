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

# Configure VPC1
resource "aws_vpc" "vpc1" {
  cidr_block  = "10.10.0.0/16"
  tags = {
    Name = "vpc1"
  }
}

# Configure a subnet in VPC1
resource "aws_subnet" "cidr1" {
  depends_on        = [aws_vpc.vpc1]
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.10.10.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "cidr1"
  }
}

# Configure a Security Groups to allow HTTP/S, SSH and ICMP PINGs
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
    description = "HTTPS from Anywhere"
    from_port   = 443
    to_port     = 443
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


# Configuring EC2 Instance for webserver in VPC1
resource "aws_instance" "webserver" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  key_name      = aws_key_pair.ubuntu.key_name
  subnet_id     = aws_subnet.cidr1.id
  private_ip    = "10.10.10.10"
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.sg1.id ]

  # Copies the index.html file to the webserver instance
  provisioner "file" {
    source      = "index.html"
    destination = "/home/ubuntu/index.html"
  }

  # Install Python and run SimpleHTTPServer on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -qq",
      "sudo apt install -y python",
      "python -m SimpleHTTPServer 80 &",
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("key")
  }

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