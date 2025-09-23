provider "aws" {
  region = var.aws_region
  
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name                   = var.name
  cluster_version                = var.k8s_version
  cluster_endpoint_public_access = true
  
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  create_cluster_security_group = false
  create_node_security_group    = false
  
  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    coredns = {}
  }
  
  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.micro"]
      min_size     = 1
      max_size     = 5
      desired_size = 2
    }
  }

  tags = var.tags
}