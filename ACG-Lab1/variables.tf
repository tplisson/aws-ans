variable "aws_region" {
    description = "AWS Region"
    default     = "us-east-1"
}
variable "aws_az1" {
    description = "AWS Availability Zone 1"
    default     = "us-east-1a"
}
variable "aws_az2" {
    description = "AWS Availability Zone 2"
    default     = "us-east-1b"
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "192.168.0.0/16"
}
variable "subnet_public1" {
  description = "CIDR block for the subnet"
  default     = "192.168.0.0/26"
}
variable "subnet_public2" {
  description = "CIDR block for the subnet"
  default     = "192.168.0.64/26"
}
variable "subnet_private3" {
  description = "CIDR block for the subnet"
  default     = "192.168.0.128/26"
}
variable "subnet_private4" {
  description = "CIDR block for the subnet"
  default     = "192.168.0.192/26"
}
variable "ec2_ip1" {
  description = "EC2's IPv4 address"
  default     = "192.168.0.10"
}