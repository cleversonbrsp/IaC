resource "oci_containerengine_cluster" "k8s_cluster" {
  cluster_pod_network_options {
		cni_type = "FLANNEL_OVERLAY"
	}
  compartment_id     = coalesce(var.comp_id, var.compartment_id)
  kubernetes_version = "v1.33.1"
  name               = "oke-cluster-managed-nodes"
  vcn_id             = module.vcn.vcn_id
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.vcn_public_subnet.id
  }
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/18"
    }
    service_lb_subnet_ids = [oci_core_subnet.vcn_service_subnet.id]
  }
  type = "ENHANCED_CLUSTER"
}
data "oci_identity_availability_domains" "ads" {
  compartment_id = coalesce(var.comp_id, var.compartment_id)
}
resource "oci_containerengine_node_pool" "kube-system" {
	cluster_id = oci_containerengine_cluster.k8s_cluster.id
	compartment_id = coalesce(var.comp_id, var.compartment_id)
	name = "managed-kube-system-pool"
  kubernetes_version = "v1.33.1"
	node_config_details {
    placement_configs {
		availability_domain = var.oci_ad
		subnet_id = oci_core_subnet.vcn_private_subnet.id
	}
  
  size = "1"
  }
  node_shape = "VM.Standard.E4.Flex"

  node_shape_config {
    memory_in_gbs = 6
    ocpus         = 2
  }

  node_source_details {
    image_id    = var.image_id
    source_type = "image"
  }

  initial_node_labels {
    key   = "name"
    value = "kube-system"
  }

  initial_node_labels {
    key   = "k8s-app"
    value = "kube-dns-autoscaler"
  }

  initial_node_labels {
    key   = "app"
    value = "cluster-autoscaler"
  }

  ssh_public_key = "${file(coalesce(var.ssh_instances_key, var.ssh_public_key))}"
  
}
resource "oci_containerengine_node_pool" "amapi-backend-pool" {
	cluster_id = oci_containerengine_cluster.k8s_cluster.id
	compartment_id = coalesce(var.comp_id, var.compartment_id)
	name = "managed-backend-pool"
  kubernetes_version = "v1.33.1"
	node_config_details {
    placement_configs {
		availability_domain = var.oci_ad
		subnet_id = oci_core_subnet.vcn_private_subnet.id
	}
  
  size = "2"
  }
  node_shape = "VM.Standard.E4.Flex"

  node_shape_config {
    memory_in_gbs = 14
    ocpus         = 2
  }

  node_source_details {
    image_id    = var.image_id
    source_type = "image"
  }
  
  initial_node_labels {
    key   = "name"
    value = "managed-backend-pool"
  }
  ssh_public_key = "${file(coalesce(var.ssh_instances_key, var.ssh_public_key))}"
}
resource "oci_containerengine_node_pool" "amapi-ms-pool" {
	cluster_id = oci_containerengine_cluster.k8s_cluster.id
	compartment_id = coalesce(var.comp_id, var.compartment_id)
	name = "managed-ms-pool"
  kubernetes_version = "v1.33.1"
	node_config_details {
    placement_configs {
		availability_domain = var.oci_ad
		subnet_id = oci_core_subnet.vcn_private_subnet.id
	}
  
  size = "1"
  }
  node_shape = "VM.Standard.E4.Flex"

  node_shape_config {
    memory_in_gbs = 12
    ocpus         = 4
  }

  node_source_details {
    image_id    = var.image_id
    source_type = "image"
  }
  
  initial_node_labels {
    key   = "name"
    value = "managed-ms-pool"
  }
  ssh_public_key = "${file(coalesce(var.ssh_instances_key, var.ssh_public_key))}"
}
resource "oci_containerengine_node_pool" "amapi-keycloak-pool" {
	cluster_id = oci_containerengine_cluster.k8s_cluster.id
	compartment_id = coalesce(var.comp_id, var.compartment_id)
	name = "managed-keycloak-pool"
  kubernetes_version = "v1.33.1"
	node_config_details {
    placement_configs {
		availability_domain = var.oci_ad
		subnet_id = oci_core_subnet.vcn_private_subnet.id
	}
  
  size = "1"
  }
  node_shape = "VM.Standard.E4.Flex"

  node_shape_config {
    memory_in_gbs = 8
    ocpus         = 2
  }

  node_source_details {
    image_id    = var.image_id
    source_type = "image"
  }
  
  initial_node_labels {
    key   = "name"
    value = "managed-keycloak-pool"
  }
  ssh_public_key = "${file(coalesce(var.ssh_instances_key, var.ssh_public_key))}"
}
resource "oci_containerengine_node_pool" "amapi-envoygateway-pool" {
	cluster_id = oci_containerengine_cluster.k8s_cluster.id
	compartment_id = coalesce(var.comp_id, var.compartment_id)
	name = "managed-envoygateway-pool"
  kubernetes_version = "v1.33.1"
	node_config_details {
    placement_configs {   
		availability_domain = var.oci_ad
		subnet_id = oci_core_subnet.vcn_private_subnet.id
	}
  
  size = "1"
  }
  node_shape = "VM.Standard.E4.Flex"

  node_shape_config {
    memory_in_gbs = 8
    ocpus         = 2
  }

  node_source_details {
    image_id    = var.image_id
    source_type = "image"
  }
  
  initial_node_labels {
    key   = "name"
    value = "managed-envoygateway-pool"
  }
  ssh_public_key = "${file(coalesce(var.ssh_instances_key, var.ssh_public_key))}"
} 
resource "oci_containerengine_node_pool" "amapi-configserver-pool" {
	cluster_id = oci_containerengine_cluster.k8s_cluster.id
	compartment_id = coalesce(var.comp_id, var.compartment_id)
	name = "managed-configserver-pool"
  kubernetes_version = "v1.33.1"
  node_config_details {
    placement_configs {
        availability_domain = var.oci_ad
        subnet_id = oci_core_subnet.vcn_private_subnet.id
    }
    size = "1"
  }
  
  node_shape = "VM.Standard.E4.Flex"

  node_shape_config {
    memory_in_gbs = 8
    ocpus         = 2
  }

  node_source_details {
    image_id    = var.image_id
    source_type = "image"
  }
  
  initial_node_labels {
    key   = "name"
    value = "managed-configserver-pool"
  }
  ssh_public_key = "${file(coalesce(var.ssh_instances_key, var.ssh_public_key))}"
} 