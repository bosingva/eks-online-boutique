resource "helm_release" "gatekeeper" {
  name                 = "openpolicyagent"
  namespace            = "openpolicyagent"
  repository           = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart                = "gatekeeper"
  version              = "3.16.3"
  create_namespace     = true
  
  depends_on           = [ module.eks, module.eks_blueprints_addons ]
}