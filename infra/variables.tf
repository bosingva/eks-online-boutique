variable "aws_region" {
  description = "AWS region where the EKS cluster will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "online-boutique-vpc"
  
}

variable "eks_cluster_name" {
  description = "Name prefix for the EKS cluster and related resources"
  type        = string
  default     = "online-boutique-eks"
}

variable "k8s_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default = {
    App = "eks-devsecops"
  }
}

variable "user_for_admin_role" {
  description = "The ARN of the IAM user that will be allowed to assume the admin role"
  type        = string
  default     = "arn:aws:iam::815254799658:user/dika"
}

variable "gitops_url" {
  description = "The URL of the GitOps Git repository"
  type        = string
  default     = ""
}

variable "gitops_password" {
  description = "The GitHub token for accessing the GitOps repository (sensitive)"
  type        = string
  sensitive   = true

}

variable "user_name_git" {
  description = "The username for accessing the GitOps repository"
  type        = string
  default     = "bosingva"
  
}
