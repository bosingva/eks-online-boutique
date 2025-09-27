provider "kubernetes" {
  host = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

resource "kubernetes_namespace" "online-boutique" {
  metadata {
    name = "online-boutique"
  }
}


resource "kubernetes_cluster_role" "cluster_viewer" {
  metadata {
    name = "cluster-viewer"
  }

  rule {
    api_groups = [""]
    resources  = ["*"]
    verbs      = ["get", "list", "watch", "describe"]
  }

    rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

    rule {
    api_groups = [""]
    resources = ["pods/portforward"]
    verbs = ["get", "list", "create"]
  }

    rule {
    api_groups = ["apiextensions.k8s.io"]
    resources = ["customresourcedefinitions"]
    verbs = ["get", "list", "describe", "create", "update", "patch", "delete"]
  }
      rule {
    api_groups = ["argoproj.io"]
    resources = ["applications"]
    verbs = ["get", "list", "describe", "create", "update", "patch", "delete"]
  }


}

resource "kubernetes_cluster_role_binding" "cluster_viewer" {
  metadata {
    name = "cluster-viewer"
  }

  role_ref {
    kind     = "ClusterRole"
    name     = "cluster-viewer"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = "admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_service_account" "externalsecrets-sa" {
  depends_on = [ aws_iam_role.externalsecrets-role ]
  metadata {
    name = "externalsecrets-sa"
    namespace = "online-boutique"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.externalsecrets-role.arn
    }
  }
}
