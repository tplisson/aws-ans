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

# Configure ATD_VPC
resource "aws_vpc" "ATD_VPC" {
  cidr_block  = var.vpc_cidr
  tags = {
    Name = "ATD_VPC"
  }
}

# Configure 4x subnets in ATD_VPC
resource "aws_subnet" "ATD_public1" {
  depends_on        = [aws_vpc.ATD_VPC]
  vpc_id            = aws_vpc.ATD_VPC.id
  cidr_block        = var.subnet_public1
  availability_zone = var.aws_az1
  tags = {
    Name = "ATD_public1"
  }
}
resource "aws_subnet" "ATD_public2" {
  depends_on        = [aws_vpc.ATD_VPC]
  vpc_id            = aws_vpc.ATD_VPC.id
  cidr_block        = var.subnet_public2
  availability_zone = var.aws_az2
  tags = {
    Name = "ATD_public2"
  }
}
resource "aws_subnet" "ATD_private3" {
  depends_on        = [aws_vpc.ATD_VPC]
  vpc_id            = aws_vpc.ATD_VPC.id
  cidr_block        = var.subnet_private3
  availability_zone = var.aws_az1
  tags = {
    Name = "ATD_private3"
  }
}
resource "aws_subnet" "ATD_private4" {
  depends_on        = [aws_vpc.ATD_VPC]
  vpc_id            = aws_vpc.ATD_VPC.id
  cidr_block        = var.subnet_private4
  availability_zone = var.aws_az2
  tags = {
    Name = "ATD_private4"
  }
}
# Configure an internet gateway
resource "aws_internet_gateway" "ATD_IGW" {
  vpc_id  = aws_vpc.ATD_VPC.id
  tags = {
    Name = "ATD_VPC-ATD_IGW"
  }
}

# Configure a default route
resource "aws_route_table" "ATD_PublicRT" {
  depends_on = [
    aws_vpc.ATD_VPC,
    aws_internet_gateway.ATD_IGW
  ]
  vpc_id = aws_vpc.ATD_VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ATD_IGW.id
  }
  tags = {
    Name = "ATD_PublicRT"
  }
}
resource "aws_route_table" "ATD_PrivateRT" {
  depends_on = [
    aws_vpc.ATD_VPC,
    aws_internet_gateway.ATD_IGW
  ]
  vpc_id = aws_vpc.ATD_VPC.id
  tags = {
    Name = "ATD_PrivateRT"
  }
}

# Associate the default route with the cidr1 subnet
resource "aws_route_table_association" "rt0-ATD_public1" {
  subnet_id      = aws_subnet.ATD_public1.id
  route_table_id = aws_route_table.ATD_PublicRT.id
}
resource "aws_route_table_association" "rt0-ATD_public2" {
  subnet_id      = aws_subnet.ATD_public2.id
  route_table_id = aws_route_table.ATD_PublicRT.id
}
resource "aws_route_table_association" "rt0-ATD_private3" {
  subnet_id      = aws_subnet.ATD_private3.id
  route_table_id = aws_route_table.ATD_PrivateRT.id
}
resource "aws_route_table_association" "rt0-ATD_private4" {
  subnet_id      = aws_subnet.ATD_private4.id
  route_table_id = aws_route_table.ATD_PrivateRT.id
}

# Configure a NACL for subnet ATD_Public1
# resource "aws_network_acl" "ATD_Public1" {
#   vpc_id      = aws_vpc.ATD_VPC.id
#   subnet_ids  = [ aws_subnet.ATD_public1.id ]

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
#     Name = "ATD_Public1"
#   }
# }

# Configure a Security Groups to allow HTTP, SSH and ICMP PINGs
resource "aws_security_group" "ATD_Bastion-SG" {
  name        = "ATD_Bastion-SG"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.ATD_VPC.id

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
  # egress {
  #   description = "Allow everything else"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  tags = {
    Name = "ATD_Bastion-SG"
  }
}

# Configuring the local SSH key
resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = file("key.pub")
}

# Configuring the cloud-init script
data "template_file" "cloud-init-config" {
  template = file("cloud-init-ec2.yaml")
}

# Configuring EC2 Instance for the Bastion Host in the Public subnet
resource "aws_instance" "BastionHost" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  key_name      = aws_key_pair.key.key_name
  subnet_id     = aws_subnet.ATD_public1.id
  private_ip    = var.ec2_ip1
  associate_public_ip_address = true
  vpc_security_group_ids  = [ aws_security_group.ATD_Bastion-SG.id ]
  user_data               = data.template_file.cloud-init-config.rendered 
  tags = {
    "Name"      = "BastionHost"
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

# Configure a Security Group for ATD_Private34_SecGrp
resource "aws_security_group" "ATD_Private34_SecGrp" {
  name        = "ATD_Private34_SecGrp"
  description = "Allow traffic to subnets Private3 and 4"
  vpc_id      = aws_vpc.ATD_VPC.id

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
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ATD_Private34_SecGrp"
  }
}

# Configuring EC2 Instance in the Private3 Subnet
resource "aws_instance" "ATD_Private3" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  key_name      = aws_key_pair.key.key_name
  subnet_id     = aws_subnet.ATD_private3.id
  private_ip    = var.ec2_ip2
  associate_public_ip_address = false
  vpc_security_group_ids  = [ aws_security_group.ATD_Private34_SecGrp.id ]
  user_data               = data.template_file.cloud-init-config.rendered 
  tags = {
    "Name"      = "App-Servers3"
  }
}

# Configuring EC2 Instance in the Private4 Subnet
resource "aws_instance" "ATD_Private4" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.nano"
  key_name      = aws_key_pair.key.key_name
  subnet_id     = aws_subnet.ATD_private4.id
  private_ip    = var.ec2_ip3
  associate_public_ip_address = false
  vpc_security_group_ids  = [ aws_security_group.ATD_Private34_SecGrp.id ]
  user_data               = data.template_file.cloud-init-config.rendered 
  tags = {
    "Name"      = "App-Servers4"
  }
}