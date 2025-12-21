# ========================================
# VPN Compute Instance (OpenVPN)
# ========================================

resource "oci_core_instance" "openvpn_instance" {
  availability_domain = var.availability_domain
  compartment_id      = local.compartment_id
  display_name        = var.instance_display_name
  shape               = var.instance_shape

  shape_config {
    memory_in_gbs = var.instance_shape_config.memory_in_gbs
    ocpus         = var.instance_shape_config.ocpus
  }

  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip          = var.assign_public_ip
    subnet_id                 = var.subnet_id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
  }

  source_details {
    source_id   = var.image_id
    source_type = "image"
  }

  agent_config {
    is_management_disabled = false
    is_monitoring_disabled = false
  }

  defined_tags = local.defined_tags
}

