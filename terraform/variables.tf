variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used in resource names."
  type        = string
  default     = "gocartops"
}

variable "environment" {
  description = "Environment name such as dev, staging, or prod."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to use. Keep 2 for lower-cost dev."
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs. Must have at least az_count values."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs. Must have at least az_count values."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway so private EKS nodes can reach ECR and the internet."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one NAT Gateway for dev cost optimization. Use false for higher availability."
  type        = bool
  default     = true
}

variable "ecr_repository_names" {
  description = "ECR repositories for Go microservices."
  type        = list(string)
  default     = ["product-service", "order-service"]
}

variable "ecr_image_tag_mutability" {
  description = "ECR tag mutability. MUTABLE is simple for dev; IMMUTABLE is safer for prod."
  type        = string
  default     = "MUTABLE"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Set to null to let AWS choose the default."
  type        = string
  default     = null
}

variable "cluster_endpoint_public" {
  description = "Enable public access to the EKS API endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_private" {
  description = "Enable private access to the EKS API endpoint."
  type        = bool
  default     = true
}

variable "cluster_public_access_cidrs" {
  description = "CIDR blocks allowed to access public EKS API endpoint. Replace with your IP for better security."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_group_name" {
  description = "EKS managed node group name."
  type        = string
  default     = "gocartops-ng"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "EKS node capacity type: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "EBS disk size in GB for each EKS worker node."
  type        = number
  default     = 30
}

variable "cluster_addons" {
  description = "EKS managed addons to install."
  type        = list(string)
  default     = ["vpc-cni", "kube-proxy", "coredns", "aws-ebs-csi-driver"]
}

variable "sqs_visibility_timeout_seconds" {
  description = "SQS visibility timeout."
  type        = number
  default     = 30
}

variable "sqs_message_retention_seconds" {
  description = "SQS message retention."
  type        = number
  default     = 345600
}

variable "sqs_max_receive_count" {
  description = "How many times a message can be received before moving to DLQ."
  type        = number
  default     = 5
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "gocartopsdb"
}

variable "db_username" {
  description = "PostgreSQL admin username."
  type        = string
  default     = "gocartadmin"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version. Set null to use AWS default."
  type        = string
  default     = null
}

variable "db_backup_retention" {
  description = "RDS backup retention in days."
  type        = number
  default     = 1
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS. Keep false for lower-cost dev."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection. Keep false for dev terraform destroy."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when deleting RDS. Keep true for dev."
  type        = bool
  default     = true
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace where Helm will deploy the services."
  type        = string
  default     = "gocartops-dev"
}

variable "order_service_account_name" {
  description = "Kubernetes service account name for order-service IRSA."
  type        = string
  default     = "order-service-sa"
}

variable "product_service_account_name" {
  description = "Kubernetes service account name for product-service IRSA."
  type        = string
  default     = "product-service-sa"
}
