# ========================================
# OKE Cluster Outputs
# ========================================

output "cluster_id" {
  description = "OCID of the OKE cluster"
  value       = oci_containerengine_cluster.nvt_oke_cluster.id
}

output "cluster_name" {
  description = "Name of the OKE cluster"
  value       = oci_containerengine_cluster.nvt_oke_cluster.name
}

output "cluster_kubernetes_version" {
  description = "Kubernetes version of the cluster"
  value       = oci_containerengine_cluster.nvt_oke_cluster.kubernetes_version
}

output "cluster_endpoints" {
  description = "Endpoints of the OKE cluster"
  value       = oci_containerengine_cluster.nvt_oke_cluster.endpoints
}

output "node_pool_id" {
  description = "OCID of the node pool"
  value       = oci_containerengine_node_pool.node_pool01.id
}

output "node_pool_name" {
  description = "Name of the node pool"
  value       = oci_containerengine_node_pool.node_pool01.name
}

