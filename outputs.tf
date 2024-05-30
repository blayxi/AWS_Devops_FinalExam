output "s3_bucket_name" {
  value = aws_s3_bucket.sbk_s3_bucket.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.sbk_rds.endpoint
}

output "kms_key_id" {
  value = aws_kms_key.sbk_key.id
}

output "load_balancer_dns_name" {
  value = aws_lb.sbk_lb.dns_name
}
