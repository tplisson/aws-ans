variable "AWS-REGION" {
  description = "AWS Region"
  default     = "us-east-1"
}
variable "AZa" {
  description = "AWS Availability Zone a"
  default     = "us-east-1a"
}
variable "AZb" {
  description = "AWS Availability Zone b"
  default     = "us-east-1b"
}
variable "AZc" {
  description = "AWS Availability Zone c"
  default     = "us-east-1c"
}
variable "VPC-A-CIDR" {
  description = "CIDR block for the VPC-A"
  default     = "172.31.0.0/16"
}
variable "VPC-B-CIDR" {
  description = "CIDR block for the VPC-B"
  default     = "10.0.0.0/16"
}
variable "SUBNET-AZa-PUBLIC" {
  description = "CIDR block for the subnet"
  default     = "172.31.80.0/20"
}
variable "SUBNET-AZa-PRIVATE" {
  description = "CIDR block for the subnet"
  default     = "172.31.96.0/20"
}
variable "SUBNET-AZb-PRIVATE" {
  description = "CIDR block for the subnet"
  default     = "10.0.8.0/21"
}
variable "SUBNET-AZc-PRIVATE" {
  description = "CIDR block for the subnet"
  default     = "10.0.16.0/21"
}
variable "PUBLIC-JUMP-BOX-IP" {
  description = "EC2's IPv4 address in the AZa-PUBLIC subnet"
  default     = "172.31.80.10"
}
variable "PRIVATE-CONSUMER-BOX-IP" {
  description = "EC2's IPv4 address in the AZa-PRIVATE subnet"
  default     = "172.31.96.10"
}
variable "PRIVATE-PROVIDER-BOX1-IP" {
  description = "EC2's IPv4 address in the AZb-PRIVATE subnet"
  default     = "10.0.8.10"
}
variable "PRIVATE-PROVIDER-BOX2-IP" {
  description = "EC2's IPv4 address in the AZc-PRIVATE subnet"
  default     = "10.0.16.10"
}
