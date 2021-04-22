# S3 Bucket with Static Website Hosting
resource "aws_s3_bucket" "b" {
  bucket = "static.${var.FQDN}"
  acl    = "public-read-write"
  policy = file("policy.json")
  website {
    index_document = "index.html"
    error_document = "error.html"
    routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
  }
}

# Copy the appropriate HTML files to the S3 bucket
resource "aws_s3_object_copy" "index" {
  bucket = "static.${var.FQDN}"
  key    = "destination_key"
  source = "index.html"
}
resource "aws_s3_object_copy" "error" {
  bucket = "static.${var.FQDN}"
  key    = "destination_key"
  source = "error.html"
}

# Configuring a Route53 DNS A record for the Static website
resource "aws_route53_record" "static" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "static.${var.FQDN}"
  type    = "A"
  ttl     = "300"
  records = ["static.${var.FQDN}"]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name = var.domain_name
  type = "A"
  alias {
    name = aws_s3_bucket.website_bucket.website_domain
    zone_id = aws_s3_bucket.website_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}