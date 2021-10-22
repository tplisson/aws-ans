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
  region = var.AWS-REGION
}

# Configure an S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = var.S3-BUCKET
  tags = {
    "Name" = var.S3-BUCKET
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Configure the S3 bucket policy
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid":"PublicList",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:ListBucket",
            "Resource": "${aws_s3_bucket.bucket.arn}"
        },
        {
            "Sid":"PublicList",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [ "s3:GetObject", "s3:GetObjectVersion" ],
            "Resource": "${aws_s3_bucket.bucket.arn}/*"
        }
    ]
}
POLICY

}

/*   # Terraform's "jsonencode" function converts a
  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = var.S3-BUCKET
    Statement = [
      {
        Sid       = "IPAllow"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.B.arn,
          "${aws_s3_bucket.B.arn}/*",
        ]
      },
    ]
  }) */

/*     Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource = [ aws_s3_bucket.B.arn ]
      },
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = [ "s3:GetObject", "s3:PutObject" ],
        Resource = [ "${aws_s3_bucket.B.arn}/*" ]
      },
    ]
  })
} */

# Configure S3 objects
resource "aws_s3_bucket_object" "whizlabs_logo" {
  bucket = aws_s3_bucket.bucket.id
  key    = "whizlabs_logo.png"
  source = "whizlabs_logo.png"
  tags = {
    "Name" = "Logo"
  }
}
resource "aws_s3_bucket_object" "index" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "index.html"
  content = "<h1>Hello, world</h1>"
  content_type = "text/html"
  tags = {
    "Name" = "Index"
  }
}
resource "aws_s3_bucket_object" "error" {
  bucket = aws_s3_bucket.bucket.id
  key    = "CustomErrors/error.html"
  source = "CustomErrors/error.html"
  
  tags = {
    "Name" = "error.html"
  }
}
resource "aws_s3_bucket_object" "block" {
  bucket = aws_s3_bucket.bucket.id
  key    = "CustomErrors/block.html"
  source = "CustomErrors/block.html"
  tags = {
    "Name" = "block.html"
  }
}

# Configure the CloudFront distribution
locals {
  s3_origin_id = var.S3-BUCKET
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }
  enabled   = true
  default_root_object = "index.html"
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "FR"]
    }
  }
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.S3-BUCKET
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/CustomErrors/error.html"
  }
  custom_error_response {
    error_code            = 403
    response_code         = 403
    response_page_path    = "/CustomErrors/block.html"
  }
  tags = {
    "Name" = "Whizlabs Lab1 CloudFront Distribution"
  }
}