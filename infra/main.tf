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

  manage_aws_auth_configmap = true
  aws_auth_roles = local.aws_k8s_role_mapping
  
    eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.small"]
      min_size     = 2
      max_size     = 10
      desired_size = 4
    }
  }

  tags = var.tags
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "1.22.0"
  
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

    eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_aws_load_balancer_controller    = true
  enable_metrics_server                  = true
  enable_cluster_autoscaler              = true
  cluster_autoscaler = {
    set = [
      {
        name = "extraArgs.scale-down-unneeded-time"
        value = "1m"
      },
      {
        name = "extraArgs.skip-nodes-with-local-storage"
        value = false
      },
      {
        name = "extraArgs.skip-nodes-with-system-pods"
        value = false
      }
    ]
  }
}
