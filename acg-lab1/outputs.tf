output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.BASTION.public_ip
}
output "aws_eip" {
  description = "Elastic IP for the NAT Gateway"
  value       = aws_eip.EIP1.public_ip
}
