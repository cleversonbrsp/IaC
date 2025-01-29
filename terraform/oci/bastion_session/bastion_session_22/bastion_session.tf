resource "oci_bastion_bastion" "nvt_bastion" {
    name = var.bastion_name
    bastion_type = var.bastion_type
    compartment_id = var.nvt_cloud_prod_comp
    target_subnet_id = var.subnet_pvt2
    client_cidr_block_allow_list = var.block_allow_list

}

resource "oci_bastion_session" "ssh_session" {

  bastion_id = oci_bastion_bastion.nvt_bastion.id
  key_details {
    public_key_content = var.ssh_bastion_key
  }
  target_resource_details {
    session_type       = var.session_type
    target_resource_id = var.target_ocid
    target_resource_operating_system_user_name = var.instance_user
    target_resource_port                       = var.target_resource_port
    target_resource_private_ip_address         = var.target_resource_instance
  }

  display_name           = "github-runner-07-vm-prod"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800

  depends_on = [ oci_bastion_bastion.nvt_bastion ]
}