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
  default     = "10.0.0.0/16"
}
variable "SUBNET-PUBLIC1" {
  description = "CIDR block for the subnet"
  default     = "10.0.1.0/24"
}
variable "SUBNET-PUBLIC2" {
  description = "CIDR block for the subnet"
  default     = "10.0.2.0/24"
}
variable "EC2-IP1" {
  description = "EC2's IPv4 address in the PUBLIC1 subnet"
  default     = "10.0.1.10"
}
variable "EC2-IP2" {
  description = "EC2's IPv4 address in the PUBLIC2 subnet"
  default     = "10.0.2.10"
}
variable "FQDN" {
  description = "Fully Qualified Domain Name"
  default     = "cmcloudlab1783.info"
}