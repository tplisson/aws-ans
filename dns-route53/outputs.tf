output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = [ aws_instance.web1.public_ip, aws_instance.web2.public_ip ]
}