data "aws_caller_identity" "current" {}

locals {
  default_kms_alias_name = "alias/${var.project_name}-${var.environment}-kms"

  kms_alias_name = (
    var.alias_name != null && trimspace(var.alias_name) != ""
    ? trimspace(var.alias_name)
    : local.default_kms_alias_name
  )
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid    = "EnableRootAccountPermissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.key_administrators) > 0 ? [1] : []

    content {
      sid    = "AllowKeyAdministrators"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.key_administrators
      }

      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.key_users) > 0 ? [1] : []

    content {
      sid    = "AllowKeyUsers"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.key_users
      }

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ]

      resources = ["*"]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.multi_region
  policy                  = data.aws_iam_policy_document.kms_policy.json

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-kms"
  })
}

resource "aws_kms_alias" "this" {
  name          = local.kms_alias_name
  target_key_id = aws_kms_key.this.key_id
}