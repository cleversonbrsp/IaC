# ========================================
# OKE Cluster
# ========================================

resource "oci_containerengine_cluster" "nvt_oke_cluster" {
  cluster_pod_network_options {
    cni_type = var.cni_type
  }
  compartment_id = local.compartment_id
  endpoint_config {
    is_public_ip_enabled = var.is_public_ip_enabled
    subnet_id            = var.oke_api_endpoint_subnet_id
  }
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  options {
    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }
    persistent_volume_config {
    }
    service_lb_config {
    }
    service_lb_subnet_ids = [var.oke_lb_subnet_id]
  }
  type   = var.cluster_type
  vcn_id = var.vcn_id
  defined_tags = local.defined_tags
}

# ========================================
# Node Pool
# ========================================

resource "oci_containerengine_node_pool" "node_pool01" {
  cluster_id     = oci_containerengine_cluster.nvt_oke_cluster.id
  compartment_id = local.compartment_id
  node_shape     = var.node_shape
  name           = var.node_pool_name

  kubernetes_version = var.node_kubernetes_version

  initial_node_labels {
    key   = "CreatedBy"
    value = "Terraform"
  }

  node_config_details {
    node_pool_pod_network_option_details {
      cni_type          = var.cni_type
      max_pods_per_node = var.max_pods_per_node
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = var.oke_node_subnet_id
    }
    size = var.node_pool_size
  }
  node_eviction_node_pool_settings {
    eviction_grace_duration              = "PT60M"
    is_force_delete_after_grace_duration = false
  }
  node_shape_config {
    memory_in_gbs = var.node_shape_config.memory_in_gbs
    ocpus         = var.node_shape_config.ocpus
  }
  node_source_details {
    image_id    = var.image_id
    source_type = "IMAGE"
  }
  defined_tags = local.defined_tags
}

