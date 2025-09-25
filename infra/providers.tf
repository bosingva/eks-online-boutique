terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "dk-s3-for-terraform-state"
    key            = "eks-online-boutique/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-online-boutique-terraform-lock"
    encrypt        = true
  }
}