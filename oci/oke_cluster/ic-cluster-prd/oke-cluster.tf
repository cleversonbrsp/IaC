resource "oci_containerengine_cluster" "generated_oci_containerengine_cluster" {
	cluster_pod_network_options {
		cni_type = "FLANNEL_OVERLAY"
	}
	compartment_id = var.oci_root_compartment
	endpoint_config {
		is_public_ip_enabled = "true"
		subnet_id = oci_core_subnet.kubernetes_api_endpoint_subnet.id
	}
	kubernetes_version = "v1.28.2"
	name = "ic-cluster-prd"
	options {
		kubernetes_network_config {
			pods_cidr = "10.244.0.0/16"
			services_cidr = "10.96.0.0/16"
		}
		persistent_volume_config {
		}
		service_lb_config {
		}
		service_lb_subnet_ids = ["${oci_core_subnet.service_lb_subnet.id}"]
	}
	type = "ENHANCED_CLUSTER"
	vcn_id = oci_core_vcn.generated_oci_core_vcn.id
}
resource "oci_containerengine_node_pool" "create_node_pool_details0" {
	cluster_id = "${oci_containerengine_cluster.generated_oci_containerengine_cluster.id}"
	compartment_id = var.oci_root_compartment
	initial_node_labels {
		key = "name"
		value = "pool1"
	}
	kubernetes_version = "v1.28.2"
	name = "pool1"
	node_config_details {
		node_pool_pod_network_option_details {
			cni_type = "FLANNEL_OVERLAY"
			max_pods_per_node = "31"
		}
		placement_configs {
			availability_domain = var.oci_ad
			fault_domains = ["FAULT-DOMAIN-2"]
			subnet_id = oci_core_subnet.node_subnet.id
		}
		size = "3"
	}
	node_eviction_node_pool_settings {
		eviction_grace_duration = "PT60M"
		is_force_delete_after_grace_duration = "false"
	}
	node_shape = "VM.Standard.E3.Flex"
	node_shape_config {
		memory_in_gbs = "8"
		ocpus = "1"
	}
	node_source_details {
		image_id = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaatmopjcmy2gp3725id6op5gdknjyykjnd7u7vdtq2tgtnn7xclioa"
		source_type = "IMAGE"
	}
}
# resource "oci_containerengine_node_pool" "create_node_pool_details1" {
# 	cluster_id = "${oci_containerengine_cluster.generated_oci_containerengine_cluster.id}"
# 	compartment_id = var.oci_root_compartment
# 	initial_node_labels {
# 		key = "name"
# 		value = "oke-pool1"
# 	}
# 	kubernetes_version = "v1.28.2"
# 	name = "oke-pool1"
# 	node_config_details {
# 		node_pool_pod_network_option_details {
# 			cni_type = "FLANNEL_OVERLAY"
# 			max_pods_per_node = "31"
# 		}
# 		placement_configs {
# 			availability_domain = var.oci_ad
# 			fault_domains = ["FAULT-DOMAIN-2"]
# 			subnet_id = oci_core_subnet.node_subnet.id
# 		}
# 		size = "2"
# 	}
# 	node_eviction_node_pool_settings {
# 		eviction_grace_duration = "PT60M"
# 		is_force_delete_after_grace_duration = "false"
# 	}
# 	node_shape = "VM.Standard.E3.Flex"
# 	node_shape_config {
# 		memory_in_gbs = "8"
# 		ocpus = "1"
# 	}
# 	node_source_details {
# 		image_id = var.node_img
# 		source_type = "IMAGE"
# 	}
# }
