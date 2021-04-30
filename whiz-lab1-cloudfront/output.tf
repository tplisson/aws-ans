output "aws_cloudfront_distribution" {
  description = "Public IP address of the EC2 instance"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}