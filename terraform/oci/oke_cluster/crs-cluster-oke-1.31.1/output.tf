output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = oci_containerengine_cluster.generated_oci_containerengine_cluster.id
}

output "nodepool_ids" {
  description = "Map of Nodepool names and IDs"
  value       = oci_containerengine_node_pool.create_node_pool_details0.id
}

output "oke_compartment_ocid" {
  description = "OCID do compartimento onde o OKE será provisionado"
  value       = oci_identity_compartment.oke_comp.id
}
