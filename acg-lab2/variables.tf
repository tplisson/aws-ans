variable "AWS-REGION" {
  description = "AWS Region"
  default     = "us-east-1"
}
variable "VPCE-DEMO-CIDR" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
variable "AWS-AZ1" {
  description = "AWS Availability Zone 1"
  default     = "us-east-1a"
}
variable "SUBNET-PUBLIC" {
  description = "CIDR block for the subnet"
  default     = "10.0.0.0/24"
}
variable "SUBNET-PRIVATE" {
  description = "CIDR block for the subnet"
  default     = "10.0.1.0/24"
}
variable "EC2-PUBLIC-IP" {
  description = "EC2's IPv4 address in the PUBLIC subnet"
  default     = "10.0.0.10"
}
variable "EC2-PRIVATE-IP" {
  description = "EC2's IPv4 address in the PRIVATE subnet"
  default     = "10.0.1.11"
}