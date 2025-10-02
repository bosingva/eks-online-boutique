variable aws_region {
  default = "us-east-1"
}

# variable aws_access_key_id {}
# variable aws_secret_access_key {}

variable name {
    default = "online-boutique-eks"
}

variable k8s_version {
    default = "1.32"
}

variable vpc_cidr_block {
    default = "10.0.0.0/16"
}
variable private_subnet_cidr_blocks {
    default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
variable public_subnet_cidr_blocks {
    default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}


variable tags {
  default = {
      App  = "eks-devsecops"
  }
}

variable "user_for_admin_role" {
  description = "The ARN of the user that will be allowed to assume the admin role"
  type        = string
  default     = "arn:aws:iam::815254799658:user/dika"
  
}

variable "gitops_url" {
  description = "The URL of the Git repository"
  type        = string
  default     = ""
}

variable "gitops_password" {
  description = "The GitHub token for accessing the repository"
  type        = string
  default = "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"

}