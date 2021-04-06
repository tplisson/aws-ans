variable "aws_region" {
    description = "AWS Region"
    default     = "us-east-1"
}
variable "aws_az1" {
    description = "AWS Availability Zone 1"
    default     = "us-east-1a"
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.10.0.0/16"
}
variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  default     = "10.10.10.0/24"
}
variable "ec2_ip1" {
  description = "EC2's IPv4 address"
  default     = "10.10.10.10"
}