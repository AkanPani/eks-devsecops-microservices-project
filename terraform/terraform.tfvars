aws_region   = "ap-south-1"
project_name = "gocartops"
environment  = "dev"

# Networking
vpc_cidr             = "10.20.0.0/16"
az_count             = 2
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]

# NAT Gateway costs money. Keep true for private EKS nodes to pull from ECR.
enable_nat_gateway = true
single_nat_gateway = true

# ECR
ecr_repository_names     = ["product-service", "order-service"]
ecr_image_tag_mutability = "MUTABLE"

# EKS
kubernetes_version          = null
cluster_endpoint_public     = true
cluster_endpoint_private    = true
cluster_public_access_cidrs = ["0.0.0.0/0"] # Replace with your public IP /32 for safer access.

node_group_name     = "gocartops-dev-ng"
node_instance_types = ["t3.small"]
node_capacity_type  = "ON_DEMAND"
node_desired_size   = 4
node_min_size       = 2
node_max_size       = 4
node_disk_size      = 20

# SQS
sqs_visibility_timeout_seconds = 30
sqs_message_retention_seconds  = 345600
sqs_max_receive_count          = 5

# RDS PostgreSQL
db_name                = "gocartopsdb"
db_username            = "gocartadmin"
db_instance_class      = "db.t3.micro"
db_allocated_storage   = 20
db_engine_version      = null
db_backup_retention    = 1
db_multi_az            = false
db_deletion_protection = false
db_skip_final_snapshot = true

# Kubernetes service accounts for IRSA
kubernetes_namespace         = "gocartops-dev"
product_service_account_name = "product-service-sa"
order_service_account_name   = "order-service-sa"

#EC2
key_name = "test_new"