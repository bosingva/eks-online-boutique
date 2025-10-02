provider "aws" {
  region = var.aws_region
  
}

data "aws_availability_zones" "azs" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.azs.names
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/online-boutique-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/online-boutique-eks" = "shared"
  }

  tags = var.tags
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = var.name
  cluster_version                = var.k8s_version
  cluster_endpoint_public_access = true
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cluster_security_group = true
  create_node_security_group    = true
  enable_cluster_creator_admin_permissions = true
  
    eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.small"]
      min_size     = 2
      max_size     = 10
      desired_size = 4
    }
    istio = {
      instance_types = ["t3.medium"]
      min_size     = 2
      max_size     = 10
      desired_size = 4
    }
  }

node_security_group_additional_rules = {
  ingress_istio_sg = {
    description              = "LB port forward to nodes (NodePorts 30000-32767)"
    protocol                 = "TCP"
    from_port                = 30000
    to_port                  = 32767
    type                     = "ingress"
    source_security_group_id = aws_security_group.istio-gateway-lb.id
  }
    ingress_15017 = {
    description = "Cluster API to Istio Webhook (sidecar-injector.istio.io)"
    protocol    = "TCP"
    from_port   = 15017
    to_port     = 15017
    type        = "ingress"
    source_cluster_security_group         = true
  }
    ingress_15012 = {
    description = "Cluster API to nodes ports/protocols"
    protocol    = "TCP"
    from_port   = 15012
    to_port     = 15012
    type        = "ingress"
    source_cluster_security_group         = true
  }
    ingress_15090 = {
    description                   = "Istio Envoy Prometheus metrics"
    protocol                      = "tcp"
    from_port                     = 15090
    to_port                       = 15090
    type                          = "ingress"
    source_cluster_security_group = true
  }
  
}

  depends_on = [ module.vpc ]

  tags = var.tags
}

module "aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = true

  aws_auth_roles = local.aws_k8s_role_mapping
  
  depends_on = [ module.eks ]
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
  depends_on = [module.aws_auth ]
}
