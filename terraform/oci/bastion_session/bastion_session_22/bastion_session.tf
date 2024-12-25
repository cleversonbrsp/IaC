resource "oci_bastion_session" "ssh_session" {

  bastion_id = var.bastion_ocid
  key_details {
    public_key_content = var.ssh_bastion_key
  }
  target_resource_details {
    session_type       = "MANAGED_SSH"
    target_resource_id = var.target_ocid
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = "192.168.250.66"
  }

  display_name           = "PROJETOS_RMM_SRV"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}