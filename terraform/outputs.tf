output "aws_region" {
  description = "AWS region."
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_update_kubeconfig_command" {
  description = "Run this command after terraform apply."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "eks_node_security_group_id" {
  description = "EKS worker node security group ID."
  value       = module.eks.node_security_group_id
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for Docker push and Helm values."
  value       = module.ecr.repository_urls
}

output "sqs_queue_url" {
  description = "Main order SQS queue URL."
  value       = module.sqs.queue_url
}

output "sqs_queue_arn" {
  description = "Main order SQS queue ARN."
  value       = module.sqs.queue_arn
}

output "sqs_dlq_url" {
  description = "Dead-letter queue URL."
  value       = module.sqs.dlq_url
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = module.rds.db_endpoint
}

output "rds_database_name" {
  description = "RDS PostgreSQL database name."
  value       = module.rds.db_name
}

output "rds_secret_arn" {
  description = "AWS Secrets Manager secret ARN storing DB credentials."
  value       = module.rds.db_secret_arn
}

output "order_service_irsa_role_arn" {
  description = "IRSA role ARN for order-service Kubernetes service account."
  value       = module.iam.order_service_irsa_role_arn
}

output "product_service_irsa_role_arn" {
  description = "IRSA role ARN for product-service Kubernetes service account."
  value       = module.iam.product_service_irsa_role_arn
}

output "kms_key_arn" {
  value = module.project_kms.key_arn
}

output "kms_alias_name" {
  value = module.project_kms.alias_name
}

output "acm_certificate_arn" {
  value = module.project_acm.certificate_arn
}

output "route53_name_servers" {
  description = "Name servers for the Route 53 hosted zone"
  value       = module.project_acm.name_servers
}