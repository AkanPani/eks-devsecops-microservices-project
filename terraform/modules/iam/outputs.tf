output "order_service_irsa_role_arn" {
  value = aws_iam_role.order_service_irsa.arn
}

output "product_service_irsa_role_arn" {
  value = aws_iam_role.product_service_irsa.arn
}
