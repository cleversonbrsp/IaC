resource "oci_core_instance" "vpn" {
  availability_domain = local.selected_ad_name
  compartment_id      = local.compartment_id
  display_name          = var.vpn_instance_display_name

  shape = var.vpn_instance_shape
  dynamic "shape_config" {
    for_each = strcontains(var.vpn_instance_shape, "Flex") ? [1] : []
    content {
      ocpus         = var.vpn_instance_ocpus
      memory_in_gbs = var.vpn_instance_memory_gbs
    }
  }

  source_details {
    source_type = "image"
    source_id   = local.vpn_source_image_id
  }

  create_vnic_details {
    assign_public_ip       = true
    subnet_id              = oci_core_subnet.vpn.id
    hostname_label         = var.vpn_instance_hostname_label
    private_ip             = cidrhost(var.vpn_subnet_cidr, 10)
    skip_source_dest_check = false
    display_name           = "${var.vpn_instance_display_name}-vnic"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(templatefile("${path.module}/scripts/openvpn-ubuntu-install.sh", {
      vcn_cidr     = var.vcn_cidr
      openvpn_port = var.openvpn_port
    }))
  }

  defined_tags = var.common_tags.defined_tags

  depends_on = [
    time_sleep.after_compartment,
    oci_core_subnet.vpn,
  ]

  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]

    precondition {
      condition     = local.vpn_source_image_id != ""
      error_message = "Defina instance_image_id ou vpn_image_id (OCID) no terraform.tfvars."
    }

    precondition {
      condition     = local.selected_ad_name != ""
      error_message = "Defina availability_domain_name no terraform.tfvars."
    }
  }
}

data "oci_core_vnic_attachments" "vpn_vnic_attachments" {
  compartment_id      = local.compartment_id
  availability_domain = local.selected_ad_name
  instance_id         = oci_core_instance.vpn.id
}

data "oci_core_vnic" "vpn_vnic" {
  vnic_id = data.oci_core_vnic_attachments.vpn_vnic_attachments.vnic_attachments[0].vnic_id
}
