
# Configuring the Route53 Hosted Zone
#resource "aws_route53_zone" "primary" {
#  name = var.FQDN
#}

# Configuring a Route53 DNS A record for the EC2 websites
#resource "aws_route53_record" "web1" {
#  zone_id = aws_route53_zone.primary.zone_id
#  name    = "www.${var.FQDN}"
#  type    = "A"
#  ttl     = "300"
#  records = [ aws_instance.web1.public_ip ]
#  set_identifier = "web1"
#  weighted_routing_policy {
#    weight = 50
#  }
#}
#resource "aws_route53_record" "web2" {
#  zone_id = aws_route53_zone.primary.zone_id
#  name    = "www.${var.FQDN}"
#  type    = "A"
#  ttl     = "300"
#  records = [ aws_instance.web2.public_ip ]
#  set_identifier = "web2"
#  weighted_routing_policy {
#    weight = 50
#  }
#}
