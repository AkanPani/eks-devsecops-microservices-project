output "key_id" {
  description = "KMS Key ID"
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "KMS Key ARN"
  value       = aws_kms_key.this.arn
}

output "alias_name" {
  description = "KMS Alias Name"
  value       = aws_kms_alias.this.name
}

output "alias_arn" {
  description = "KMS Alias ARN"
  value       = aws_kms_alias.this.arn
}

