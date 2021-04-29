variable "AWS-REGION" {
  description = "AWS Region"
  default     = "us-east-1"
}
variable "AWS-AZ1" {
  description = "AWS Availability Zone 1"
  default     = "us-east-1a"
}
variable "AWS-AZ2" {
  description = "AWS Availability Zone 2"
  default     = "us-east-1b"
}
variable "VPC1-CIDR" {
  description = "CIDR block for the VPC"
  default     = "192.168.0.0/24"
}
variable "SUBNET-PUBLIC1" {
  description = "CIDR block for the subnet"
  default     = "192.168.0.0/26"
}
variable "SUBNET-PUBLIC2" {
  description = "CIDR block for the subnet"
  default     = "192.168.0.64/26"
}
variable "SUBNET-PRIVATE3" {
  description = "CIDR block for the subnet"
  default     = "192.168.0.128/26"
}
variable "SUBNET-PRIVATE4" {
  description = "CIDR block for the subnet"
  default     = "192.168.0.192/26"
}
variable "EC2-IP1" {
  description = "EC2's IPv4 address in the PUBLIC1 subnet"
  default     = "192.168.0.10"
}
variable "EC2-IP2" {
  description = "EC2's IPv4 address in the PRIVATE3 subnet"
  default     = "192.168.0.150"
}
variable "EC2-IP3" {
  description = "EC2's IPv4 address in the PRIVATE3 subnet"
  default     = "192.168.0.200"
}
variable "NATGW-IP" {
  description = "NAT Gateway's IPv4 address in the PUBLIC2 subnet"
  default     = "192.168.0.100"
}