output "siteurl" {
  value = aws_route53_record.site.fqdn
}

output "lb_id" {
  value = aws_lb.app_lb.id
}