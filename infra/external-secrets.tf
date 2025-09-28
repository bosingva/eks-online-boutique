resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.20.1" 
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [ module.eks, module.eks_blueprints_addons ] 
}
