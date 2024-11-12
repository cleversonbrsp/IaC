provider "kubernetes" {
  host                   = oci_containerengine_cluster.generated_oci_containerengine_cluster.endpoints.kubernetes
  token                  = oci_containerengine_cluster.generated_oci_containerengine_cluster.token
  cluster_ca_certificate = base64decode(oci_containerengine_cluster.generated_oci_containerengine_cluster.certificate_authority)
}

resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "5.0.3"

#   set {
#     name  = "server.service.type"
#     value = "LoadBalancer"
#   }
}
