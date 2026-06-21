variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "eks_oidc_issuer_url" {
  type = string
}

variable "kubernetes_namespace" {
  type = string
}

variable "order_service_account_name" {
  type = string
}

variable "product_service_account_name" {
  type = string
}

variable "sqs_queue_arns" {
  type = list(string)
}

variable "rds_secret_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "eks_oidc_provider_arn" {
  description = "OIDC provider ARN created by EKS module"
  type        = string
}
