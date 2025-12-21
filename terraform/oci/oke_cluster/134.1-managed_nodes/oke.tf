resource "oci_containerengine_cluster" "generated_oci_containerengine_cluster" {
  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }
  compartment_id = coalesce(var.comp_id, var.compartment_id)
  endpoint_config {
    is_public_ip_enabled = "true"
    subnet_id            = oci_core_subnet.kubernetes_api_endpoint_subnet.id
  }
  kubernetes_version = "v1.34.1"
  name               = "crs-cluster-hml"
  options {
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    persistent_volume_config {
    }
    service_lb_config {
    }
    service_lb_subnet_ids = ["${oci_core_subnet.service_lb_subnet.id}"]
  }
  type   = "ENHANCED_CLUSTER"
  vcn_id = oci_core_vcn.generated_oci_core_vcn.id
  defined_tags = var.common_tags.defined_tags
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = coalesce(var.comp_id, var.compartment_id)
}

resource "oci_containerengine_node_pool" "node_pool01" {
  cluster_id     = oci_containerengine_cluster.generated_oci_containerengine_cluster.id
  compartment_id = coalesce(var.comp_id, var.compartment_id)
  node_shape     = "VM.Standard.E4.Flex"
  name           = "pool01"

  kubernetes_version = "v1.34.1"
  initial_node_labels {
    key   = "CreatedBy"
    value = "cleverson"
  }

  node_config_details {
    node_pool_pod_network_option_details {
      cni_type          = "FLANNEL_OVERLAY"
      max_pods_per_node = "31"
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.node_subnet.id
    }
    size = "2"
  }
  node_eviction_node_pool_settings {
    eviction_grace_duration              = "PT60M"
    is_force_delete_after_grace_duration = false
  }
  node_shape_config {
    memory_in_gbs = "8"
    ocpus         = "1"
  }
  node_source_details {
    image_id    = var.image_id
    source_type = "IMAGE"
  }
  defined_tags = var.common_tags.defined_tags
}
