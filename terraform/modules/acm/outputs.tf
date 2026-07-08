output "certificate_arn" {
  description = "Validated ACM certificate ARN"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_name" {
  description = "Certificate domain name"
  value       = aws_acm_certificate.this.domain_name
}

output "validation_record_fqdns" {
  description = "DNS validation record FQDNs"
  value = [
    for record in aws_route53_record.validation : record.fqdn
  ]
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Route 53 hosted zone name servers"
  value       = aws_route53_zone.this.name_servers
}
