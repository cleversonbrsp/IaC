
############ cluster id ############
output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = oci_containerengine_cluster.generated_oci_containerengine_cluster.id
}

############ node pool id ############
output "nodepool_ids" {
  description = "Map of Nodepool names and IDs"
  value       = oci_containerengine_node_pool.create_node_pool_details0.id
}

############ compute instances ############
output "selfhosted_instance_public_ip" {
  description = "Public IP address of the selfhosted_instance"
  value       = oci_core_instance.selfhosted_instance.public_ip
}
output "selfhosted_instance_ocid" {
  description = "Public IP address of the selfhosted_instance"
  value       = oci_core_instance.selfhosted_instance.id
}

output "vpn_instance_public_ip" {
  description = "Public IP address of the vpn_instance"
  value       = oci_core_instance.vpn_instance.public_ip
}
output "vpn_instance_ocid" {
  description = "Public IP address of the vpn_instance"
  value       = oci_core_instance.vpn_instance.id
}