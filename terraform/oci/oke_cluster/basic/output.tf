output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = oci_containerengine_cluster.generated_oci_containerengine_cluster.id
}

output "nodepool_ids" {
  description = "Map of Nodepool names and IDs"
  value       = oci_containerengine_node_pool.node_pool01.id
}

output "oke_context" {
  value = oci_container_engine_cluster.generated_oci_containerengine_cluster.context
}
