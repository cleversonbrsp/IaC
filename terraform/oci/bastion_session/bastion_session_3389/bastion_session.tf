resource "oci_bastion_session" "rdp_session" {

  bastion_id = var.bastion_ocid
  key_details {
    public_key_content = var.ssh_bastion_key
  }
  target_resource_details {
    session_type       = "PORT_FORWARDING"
    target_resource_id = var.target_ocid
    target_resource_port                       = 3389
    target_resource_private_ip_address         = "172.17.207.131"
  }

  display_name           = "PROJETOS_AD_SESSION"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}