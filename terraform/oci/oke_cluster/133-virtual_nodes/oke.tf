resource "oci_containerengine_cluster" "k8s_cluster" {
  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }
  compartment_id     = oci_identity_compartment.crodrigues.id
  kubernetes_version = "v1.33.1"
  name               = "oke-cluster-virtual-nodes"
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
  compartment_id = oci_identity_compartment.crodrigues.id
}
resource "oci_containerengine_virtual_node_pool" "k8s_prod_pool" {
  cluster_id     = oci_containerengine_cluster.k8s_cluster.id
  compartment_id = oci_identity_compartment.crodrigues.id
  display_name   = "virtual-nodes-pool"
  initial_virtual_node_labels {
    key   = "name"
    value = "virtual-nodes-pool"
  }
  placement_configurations {
    availability_domain = var.oci_ad
    subnet_id           = oci_core_subnet.vcn_private_subnet.id
    fault_domain = ["FAULT-DOMAIN-1"]
  }
  placement_configurations {
    availability_domain = var.oci_ad
    subnet_id           = oci_core_subnet.vcn_private_subnet.id
    fault_domain = ["FAULT-DOMAIN-2"]
  }
  placement_configurations {
    availability_domain = var.oci_ad
    subnet_id           = oci_core_subnet.vcn_private_subnet.id
    fault_domain = ["FAULT-DOMAIN-3"]
  }
  pod_configuration {
    shape     = "Pod.Standard.E4.Flex"
    subnet_id = oci_core_subnet.vcn_private_subnet.id
  }
  size = "3"
}