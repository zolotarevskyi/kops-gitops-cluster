output "s3_bucket" {
  value = aws_s3_bucket.kops_state.bucket
}

output "kops_dns_ns_records" {
  value = aws_route53_zone.kops_zone.name_servers
}

output "kops_iam_access_key" {
  value = aws_iam_access_key.kops_credentials.id
}

output "kops_iam_secret_key" {
  value = aws_iam_access_key.kops_credentials.secret
  sensitive = true
}

