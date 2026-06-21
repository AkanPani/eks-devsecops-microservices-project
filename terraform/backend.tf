terraform {
  backend "s3" {
    bucket         = "gocartops-dev-tfstate-548932260906-ap-south-1"
    key            = "gocartops/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "gocartops-dev-tf-locks"
    encrypt        = true
  }
}
