variable aws_region {
  default = "us-east-1"
}

# variable aws_access_key_id {}
# variable aws_secret_access_key {}

variable name {
    default = "online-boutique-eks"
}

variable k8s_version {
    default = "1.33"
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