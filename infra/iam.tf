locals {
  aws_k8s_role_mapping = [{
      rolearn = aws_iam_role.external-admin.arn
      username = "admin"
      groups = ["none"]
    }
  ]
}

resource "aws_iam_role" "external-admin" {
  name = "external-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = var.user_for_admin_role
        }
      }
    ]
  })

  }
  
  resource "aws_iam_role_policy" "external-admin-policy" {
    name = "external-admin-policy"
    role = aws_iam_role.external-admin.id
  
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {       
          Action   = ["eks:DescribeCluster"]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }


