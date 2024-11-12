output "kubernetes_host" {
  value = oci_containerengine_cluster.generated_oci_containerengine_cluster.endpoints.kubernetes
}

output "kubernetes_token" {
  value     = oci_containerengine_cluster.generated_oci_containerengine_cluster.token
  sensitive = true
}

output "kubernetes_ca_certificate" {
  value = oci_containerengine_cluster.generated_oci_containerengine_cluster.certificate_authority
}
