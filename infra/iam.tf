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

resource "aws_iam_role" "externalsecrets-role" {
  name = "externalsecrets_sa_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Effect = "Allow"
        Sid    = ""
        // all services within EKS can assume this role
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
      },
    ]
  })

  }
  
resource "aws_iam_role_policy" "externalsecrets-sa-policy" {
  name = "externalsecrets_sa_policy"
  role = aws_iam_role.externalsecrets-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        // Read access to all secrets in the secrets manager
        Effect   = "Allow"
        Resource = "*"
        Action   = [
          "secretsmanager:GetRandomPassword",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets",
          "secretsmanager:BatchGetSecretValue"
        ]
      },
    ]
  })
}

