# locals {
#   oidc_provider_hostpath = replace(var.eks_oidc_issuer_url, "https://", "")
# }
#
# # data "tls_certificate" "eks" {
# #   url = var.eks_oidc_issuer_url
# # }
#
# # resource "aws_iam_openid_connect_provider" "eks" {
# #   url = var.eks_oidc_issuer_url
# #
# #   client_id_list = [
# #     "sts.amazonaws.com"
# #   ]
# #
# #   thumbprint_list = [
# #     data.tls_certificate.eks.certificates[length(data.tls_certificate.eks.certificates) - 1].sha1_fingerprint
# #   ]
# #
# #   tags = merge(var.tags, {
# #     Name = "${var.project_name}-${var.environment}-eks-oidc-provider"
# #   })
# # }
#
# data "aws_iam_policy_document" "order_service_assume_role" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#
#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_openid_connect_provider.eks.arn]
#     }
#
#     condition {
#       test     = "StringEquals"
#       variable = "${local.oidc_provider_hostpath}:aud"
#       values   = ["sts.amazonaws.com"]
#     }
#
#     condition {
#       test     = "StringEquals"
#       variable = "${local.oidc_provider_hostpath}:sub"
#       values   = ["system:serviceaccount:${var.kubernetes_namespace}:${var.order_service_account_name}"]
#     }
#   }
# }
#
# data "aws_iam_policy_document" "product_service_assume_role" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#
#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_openid_connect_provider.eks.arn]
#     }
#
#     condition {
#       test     = "StringEquals"
#       variable = "${local.oidc_provider_hostpath}:aud"
#       values   = ["sts.amazonaws.com"]
#     }
#
#     condition {
#       test     = "StringEquals"
#       variable = "${local.oidc_provider_hostpath}:sub"
#       values   = ["system:serviceaccount:${var.kubernetes_namespace}:${var.product_service_account_name}"]
#     }
#   }
# }


locals {
  oidc_provider_hostpath = replace(var.eks_oidc_issuer_url, "https://", "")
}

data "aws_iam_policy_document" "order_service_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:sub"
      values   = ["system:serviceaccount:${var.kubernetes_namespace}:${var.order_service_account_name}"]
    }
  }
}

data "aws_iam_policy_document" "product_service_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:sub"
      values   = ["system:serviceaccount:${var.kubernetes_namespace}:${var.product_service_account_name}"]
    }
  }
}

resource "aws_iam_role" "order_service_irsa" {
  name               = "${var.project_name}-${var.environment}-order-service-irsa"
  assume_role_policy = data.aws_iam_policy_document.order_service_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-order-service-irsa"
  })
}

resource "aws_iam_role" "product_service_irsa" {
  name               = "${var.project_name}-${var.environment}-product-service-irsa"
  assume_role_policy = data.aws_iam_policy_document.product_service_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-product-service-irsa"
  })
}

data "aws_iam_policy_document" "order_service_permissions" {
  statement {
    sid    = "AllowOrderServiceSQSAccess"
    effect = "Allow"

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility"
    ]

    resources = var.sqs_queue_arns
  }

  statement {
    sid    = "AllowReadDatabaseSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [var.rds_secret_arn]
  }
}

data "aws_iam_policy_document" "product_service_permissions" {
  statement {
    sid    = "AllowReadDatabaseSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [var.rds_secret_arn]
  }
}

resource "aws_iam_policy" "order_service_permissions" {
  name        = "${var.project_name}-${var.environment}-order-service-policy"
  description = "Permissions for order-service pod via IRSA"
  policy      = data.aws_iam_policy_document.order_service_permissions.json

  tags = var.tags
}

resource "aws_iam_policy" "product_service_permissions" {
  name        = "${var.project_name}-${var.environment}-product-service-policy"
  description = "Permissions for product-service pod via IRSA"
  policy      = data.aws_iam_policy_document.product_service_permissions.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "order_service_permissions" {
  role       = aws_iam_role.order_service_irsa.name
  policy_arn = aws_iam_policy.order_service_permissions.arn
}

resource "aws_iam_role_policy_attachment" "product_service_permissions" {
  role       = aws_iam_role.product_service_irsa.name
  policy_arn = aws_iam_policy.product_service_permissions.arn
}
