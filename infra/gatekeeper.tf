resource "helm_release" "gatekeeper" {
  name                 = "openpolicyagent"
  namespace            = "openpolicyagent"
  repository           = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart                = "gatekeeper"
  version              = "3.16.3"
  create_namespace     = true
  wait                 = true
  timeout              = 600
  
  depends_on           = [ module.eks, module.eks_blueprints_addons ]
}

resource "time_sleep" "wait_for_gatekeeper" {
  depends_on = [helm_release.gatekeeper]
  create_duration = "60s"
}