# output "oidc_provider_arn" {
#   value = aws_iam_openid_connect_provider.eks.arn
# }

output "order_service_irsa_role_arn" {
  value = aws_iam_role.order_service_irsa.arn
}

output "product_service_irsa_role_arn" {
  value = aws_iam_role.product_service_irsa.arn
}
