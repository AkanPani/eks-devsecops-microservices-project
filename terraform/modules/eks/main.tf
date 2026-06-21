# data "aws_iam_policy_document" "eks_cluster_assume_role" {
#   statement {
#     effect = "Allow"
#
#     principals {
#       type        = "Service"
#       identifiers = ["eks.amazonaws.com"]
#     }
#
#     actions = ["sts:AssumeRole"]
#   }
# }
#
# resource "aws_iam_role" "cluster" {
#   name               = "${var.cluster_name}-cluster-role"
#   assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
#
#   tags = merge(var.tags, {
#     Name = "${var.cluster_name}-cluster-role"
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "cluster_policy" {
#   role       = aws_iam_role.cluster.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }
#
# resource "aws_security_group" "cluster_additional" {
#   name        = "${var.cluster_name}-additional-sg"
#   description = "Additional security group for EKS control plane"
#   vpc_id      = var.vpc_id
#
#   egress {
#     description = "Allow all outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = merge(var.tags, {
#     Name = "${var.cluster_name}-additional-sg"
#   })
# }
#
# resource "aws_eks_cluster" "this" {
#   name     = var.cluster_name
#   role_arn = aws_iam_role.cluster.arn
#   version  = var.kubernetes_version
#
#   access_config {
#     authentication_mode                         = "API_AND_CONFIG_MAP"
#     bootstrap_cluster_creator_admin_permissions = true
#   }
#
#   vpc_config {
#     subnet_ids              = var.private_subnet_ids
#     security_group_ids      = [aws_security_group.cluster_additional.id]
#     endpoint_public_access  = var.cluster_endpoint_public
#     endpoint_private_access = var.cluster_endpoint_private
#     public_access_cidrs     = var.cluster_public_access_cidrs
#   }
#
#   tags = merge(var.tags, {
#     Name = var.cluster_name
#   })
#
#   depends_on = [aws_iam_role_policy_attachment.cluster_policy]
# }
#
# data "aws_iam_policy_document" "node_assume_role" {
#   statement {
#     effect = "Allow"
#
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#
#     actions = ["sts:AssumeRole"]
#   }
# }
#
# resource "aws_iam_role" "node" {
#   name               = "${var.cluster_name}-node-role"
#   assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
#
#   tags = merge(var.tags, {
#     Name = "${var.cluster_name}-node-role"
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "node_worker_policy" {
#   role       = aws_iam_role.node.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }
#
# resource "aws_iam_role_policy_attachment" "node_cni_policy" {
#   role       = aws_iam_role.node.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }
#
# resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
#   role       = aws_iam_role.node.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }
#
# resource "aws_iam_role_policy_attachment" "node_ssm_policy" {
#   role       = aws_iam_role.node.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }
#
# resource "aws_iam_role_policy_attachment" "node_ebs_csi_policy" {
#   role       = aws_iam_role.node.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }
#
# resource "aws_eks_node_group" "this" {
#   cluster_name    = aws_eks_cluster.this.name
#   node_group_name = var.node_group_name
#   node_role_arn   = aws_iam_role.node.arn
#   subnet_ids      = var.private_subnet_ids
#
#   capacity_type  = var.node_capacity_type
#   instance_types = var.node_instance_types
#   disk_size      = var.node_disk_size
#
#   scaling_config {
#     desired_size = var.node_desired_size
#     min_size     = var.node_min_size
#     max_size     = var.node_max_size
#   }
#
#   update_config {
#     max_unavailable = 1
#   }
#
#   labels = {
#     project     = var.project_name
#     environment = var.environment
#   }
#
#   tags = merge(var.tags, {
#     Name = var.node_group_name
#   })
#
#   depends_on = [
#     aws_iam_role_policy_attachment.node_worker_policy,
#     aws_iam_role_policy_attachment.node_cni_policy,
#     aws_iam_role_policy_attachment.node_ecr_policy,
#     aws_iam_role_policy_attachment.node_ssm_policy,
#     aws_iam_role_policy_attachment.node_ebs_csi_policy
#   ]
# }
#
# resource "aws_eks_addon" "this" {
#   for_each = toset(var.cluster_addons)
#
#   cluster_name = aws_eks_cluster.this.name
#   addon_name   = each.value
#
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#
#   tags = merge(var.tags, {
#     Name = "${var.cluster_name}-${each.value}"
#   })
#
#   depends_on = [aws_eks_node_group.this]
# }
#
# ########################################################################
#
# # resource "aws_eks_addon" "this" {
# #   for_each = toset(var.cluster_addons)
# #
# #   cluster_name = aws_eks_cluster.this.name
# #   addon_name   = each.value
# #
# #   service_account_role_arn = each.value == "aws-ebs-csi-driver" ? aws_iam_role.ebs_csi_driver.arn : null
# #
# #   resolve_conflicts_on_create = "OVERWRITE"
# #   resolve_conflicts_on_update = "OVERWRITE"
# #
# #   tags = merge(var.tags, {
# #     Name = "${var.cluster_name}-${each.value}"
# #   })
# #
# #   depends_on = [
# #     aws_eks_node_group.this,
# #     aws_iam_role_policy_attachment.ebs_csi_driver
# #   ]
# # }
# ########################################################################
#
# # data "aws_iam_policy_document" "ebs_csi_assume_role" {
# #   statement {
# #     effect = "Allow"
# #
# #     actions = [
# #       "sts:AssumeRoleWithWebIdentity"
# #     ]
# #
# #     principals {
# #       type        = "Federated"
# #       identifiers = [aws_iam_openid_connect_provider.eks.arn]
# #     }
# #
# #     condition {
# #       test     = "StringEquals"
# #       variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
# #       values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
# #     }
# #
# #     condition {
# #       test     = "StringEquals"
# #       variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
# #       values   = ["sts.amazonaws.com"]
# #     }
# #   }
# # }
# #
# # resource "aws_iam_role" "ebs_csi_driver" {
# #   name               = "${var.cluster_name}-ebs-csi-driver-role"
# #   assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
# # }
# #
# # resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
# #   role       = aws_iam_role.ebs_csi_driver.name
# #   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# # }
#


#############################
############################################

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"


    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]


  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_security_group" "cluster_additional" {
  name        = "${var.cluster_name}-additional-sg"
  description = "Additional security group for EKS control plane"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-additional-sg"
  })
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster_additional.id]
    endpoint_public_access  = var.cluster_endpoint_public
    endpoint_private_access = var.cluster_endpoint_private
    public_access_cidrs     = var.cluster_public_access_cidrs
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

# ============================================================

# CHANGE 1: Added OIDC provider for IRSA

# Required for EBS CSI controller service account to assume IAM role

# ============================================================

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint
  ]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-oidc-provider"
  })
}

locals {
  oidc_provider_url = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

# ============================================================

# Node IAM role

# ============================================================

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect = "Allow"


    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]


  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ============================================================

# CHANGE 2: Removed node_ebs_csi_policy

#

# Earlier you attached AmazonEBSCSIDriverPolicy to the node role.

# That did not fix your issue because the EBS CSI controller pod

# could not use node IMDS credentials.

#

# Correct approach: use IRSA with service_account_role_arn.

# ============================================================

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    project     = var.project_name
    environment = var.environment
  }

  tags = merge(var.tags, {
    Name = var.node_group_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
    aws_iam_role_policy_attachment.node_ssm_policy
  ]
}

# ============================================================

# CHANGE 3: Added EBS CSI IRSA IAM role

# This role will be assumed by:

# system:serviceaccount:kube-system:ebs-csi-controller-sa

# ============================================================

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect = "Allow"


    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }


  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.cluster_name}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ebs-csi-driver-role"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ============================================================

# EKS managed add-ons

# ============================================================

resource "aws_eks_addon" "this" {
  for_each = toset(var.cluster_addons)

  cluster_name = aws_eks_cluster.this.name
  addon_name   = each.value

  # ==========================================================

  # CHANGE 4: Attach IRSA role only to aws-ebs-csi-driver

  # This fixes serviceAccountRoleArn = null issue.

  # ==========================================================

  service_account_role_arn = each.value == "aws-ebs-csi-driver" ? aws_iam_role.ebs_csi_driver.arn : null

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.value}"
  })

  depends_on = [
    aws_eks_node_group.this,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]
}
