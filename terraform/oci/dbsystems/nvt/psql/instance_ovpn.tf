# OpenVPN instance (ephemeral public IP on VNIC). Network and NSG in network.tf.
resource "oci_core_instance" "vpn" {
  availability_domain = var.availability_domain
  compartment_id      = local.compartment_id
  display_name        = var.instance_display_name
  shape               = var.instance_shape
  defined_tags        = var.common_tags.defined_tags

  shape_config {
    memory_in_gbs = var.instance_memory_gb
    ocpus         = var.instance_ocpus
  }

  source_details {
    source_id   = var.image_id
    source_type = "image"
  }

  create_vnic_details {
    assign_public_ip       = true
    subnet_id              = oci_core_subnet.vpn_subnet.id
    hostname_label         = "ovpn-psql"
    nsg_ids                = [oci_core_network_security_group.vpn_nsg.id]
    private_ip             = cidrhost(var.vpn_subnet_cidr, 10)
    skip_source_dest_check = false
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(templatefile("${path.module}/scripts/openvpn-ubuntu-install.sh", { db_subnet_cidr = var.db_subnet_cidr, openvpn_port = var.openvpn_port != 0 ? var.openvpn_port : 1194 }))
  }

  preserve_boot_volume = false
}
