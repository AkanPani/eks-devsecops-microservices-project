terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Phase       = "phase-3-infra"
  }
}

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  cluster_name         = local.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway

  tags = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  repository_names     = var.ecr_repository_names
  image_tag_mutability = var.ecr_image_tag_mutability

  tags = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  project_name                = var.project_name
  environment                 = var.environment
  cluster_name                = local.cluster_name
  kubernetes_version          = var.kubernetes_version
  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  cluster_endpoint_public     = var.cluster_endpoint_public
  cluster_endpoint_private    = var.cluster_endpoint_private
  cluster_public_access_cidrs = var.cluster_public_access_cidrs

  node_group_name     = var.node_group_name
  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_disk_size      = var.node_disk_size
  cluster_addons      = var.cluster_addons

  tags = local.common_tags
}

module "sqs" {
  source = "./modules/sqs"

  queue_name                 = "${var.project_name}-${var.environment}-orders"
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds
  max_receive_count          = var.sqs_max_receive_count

  tags = local.common_tags
}

module "rds" {
  source = "./modules/rds"

  project_name               = var.project_name
  environment                = var.environment
  identifier                 = "${var.project_name}-${var.environment}-postgres"
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_security_group_id]

  db_name              = var.db_name
  db_username          = var.db_username
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine_version    = var.db_engine_version
  db_backup_retention  = var.db_backup_retention
  db_multi_az          = var.db_multi_az
  deletion_protection  = var.db_deletion_protection
  skip_final_snapshot  = var.db_skip_final_snapshot

  tags = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  project_name                 = var.project_name
  environment                  = var.environment
  eks_oidc_issuer_url          = module.eks.oidc_issuer_url
  kubernetes_namespace         = var.kubernetes_namespace
  order_service_account_name   = var.order_service_account_name
  product_service_account_name = var.product_service_account_name
  sqs_queue_arns               = [module.sqs.queue_arn, module.sqs.dlq_arn]
  rds_secret_arn               = module.rds.db_secret_arn
  eks_oidc_provider_arn        = module.eks.oidc_provider_arn

  depends_on = [module.eks]

  tags = local.common_tags
}
