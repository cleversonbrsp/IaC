resource "oci_core_instance" "desktop" {
  availability_domain = local.selected_ad_name
  compartment_id      = local.compartment_id
  display_name        = var.instance_display_name

  shape = var.instance_shape
  dynamic "shape_config" {
    for_each = strcontains(var.instance_shape, "Flex") ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_memory_gbs
    }
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.private.id
    assign_public_ip       = false
    display_name           = "${var.instance_display_name}-vnic"
    hostname_label         = var.instance_hostname_label
    skip_source_dest_check = false

    nsg_ids = [oci_core_network_security_group.desktop_nsg.id]
  }

  source_details {
    source_type = "image"
    source_id   = local.resolved_image_id

    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(local.desktop_cloud_init_userdata)
  }

  defined_tags = var.common_tags.defined_tags

  depends_on = [
    time_sleep.after_compartment,
    oci_core_subnet.private,
  ]

  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]

    precondition {
      condition     = local.resolved_image_id != ""
      error_message = "Defina instance_image_id (OCID) no terraform.tfvars."
    }

    precondition {
      condition     = local.selected_ad_name != ""
      error_message = "Defina availability_domain_name (ex.: YCyV:US-ASHBURN-AD-1) no terraform.tfvars."
    }
  }
}

data "oci_core_vnic_attachments" "desktop_vnic_attachments" {
  compartment_id      = local.compartment_id
  availability_domain = local.selected_ad_name
  instance_id         = oci_core_instance.desktop.id
}

data "oci_core_vnic" "desktop_vnic" {
  vnic_id = data.oci_core_vnic_attachments.desktop_vnic_attachments.vnic_attachments[0].vnic_id
}
