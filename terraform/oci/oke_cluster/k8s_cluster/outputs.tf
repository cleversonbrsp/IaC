# output "kubernetes_host" {
#   value       = oci_containerengine_cluster.generated_oci_containerengine_cluster.endpoints.kubernetes
#   description = "The Kubernetes API endpoint URL."
# }

# output "kubernetes_token" {
#   value       = oci_containerengine_cluster.generated_oci_containerengine_cluster.token
#   description = "The authentication token for the Kubernetes API."
# }

# output "kubernetes_ca_certificate" {
#   value       = oci_containerengine_cluster.generated_oci_containerengine_cluster.certificate_authority
#   description = "The CA certificate for the Kubernetes API."
# }

# Saída do OCID do Cluster OKE
output "cluster_ocid" {
  value       = oci_containerengine_cluster.generated_oci_containerengine_cluster.id
  description = "The OCID of the Kubernetes cluster."
}
