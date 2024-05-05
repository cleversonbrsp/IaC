resource "oci_bastion_session" "web_session" {

  bastion_id = var.bastion_ocid
  key_details {
    public_key_content = var.ssh_bastion_key
  }
  target_resource_details {
    session_type       = "PORT_FORWARDING"
    target_resource_id = var.target_ocid
    target_resource_port                       = 443
    target_resource_private_ip_address         = "192.168.250.66"
  }

  display_name           = "CRS_PROJ_RMM_GUI"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}