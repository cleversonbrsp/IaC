resource "oci_containerengine_cluster" "generated_oci_containerengine_cluster" {
  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }
  compartment_id = oci_identity_compartment.lab01.id
  endpoint_config {
    is_public_ip_enabled = "true"
    subnet_id            = oci_core_subnet.kubernetes_api_endpoint_subnet.id
  }
  kubernetes_version = "v1.30.1"
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
  type   = "BASIC_CLUSTER"
  vcn_id = oci_core_vcn.generated_oci_core_vcn.id
}
resource "oci_containerengine_node_pool" "node_pool01" {
  cluster_id     = oci_containerengine_cluster.generated_oci_containerengine_cluster.id
  compartment_id = oci_identity_compartment.lab01.id
  node_shape     = "VM.Standard.E3.Flex"
  name           = "pool01"

  kubernetes_version = "v1.30.1"
   initial_node_labels {
   	key = "CreatedBy"
   	value = "cleverson"
   }

  node_config_details {
    node_pool_pod_network_option_details {
      cni_type          = "FLANNEL_OVERLAY"
      max_pods_per_node = "31"
    }
    placement_configs {
      availability_domain = var.oci_ad_agak
      #fault_domains       = ["FAULT-DOMAIN-2"]
      subnet_id           = oci_core_subnet.node_subnet.id

      # preemptible_node_config {
      #   #Required
      #   preemption_action {
      #     #Required
      #     type = "TERMINATE"

      #     #Optional
      #     is_preserve_boot_volume = false
      #   }
      # }
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
    image_id    = var.node_img
    source_type = "IMAGE"
  }
}

