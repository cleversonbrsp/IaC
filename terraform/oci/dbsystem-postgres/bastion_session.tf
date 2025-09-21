# Bastion Service for PostgreSQL Access
resource "oci_bastion_bastion" "postgres_bastion" {
  name                         = "${local.name_prefix}-bastion"
  bastion_type                 = "STANDARD"
  compartment_id               = local.compartment_id
  target_subnet_id             = oci_core_subnet.postgres_public_subnet.id
  client_cidr_block_allow_list = ["0.0.0.0/0"] # Allow from anywhere - adjust as needed

  freeform_tags = local.common_tags
}

# Bastion Session for PostgreSQL Database Access
resource "oci_bastion_session" "postgres_session" {
  count = var.create_bastion_session ? 1 : 0

  bastion_id = oci_bastion_bastion.postgres_bastion.id

  key_details {
    public_key_content = var.ssh_public_key
  }

  target_resource_details {
    session_type                       = "PORT_FORWARDING"
    target_resource_port               = 5432
    target_resource_private_ip_address = local.postgres_private_ip
  }

  display_name           = "${local.name_prefix}-postgres-session"
  key_type               = "PUB"
  session_ttl_in_seconds = var.bastion_session_ttl

  depends_on = [oci_bastion_bastion.postgres_bastion, oci_psql_db_system.postgres_db_system]
}