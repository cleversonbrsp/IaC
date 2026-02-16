# Compartment e rede
output "compartment_id" {
  value = local.compartment_id
}

output "vcn_id" {
  value = oci_core_vcn.postgresql_vcn.id
}

output "subnet_id" {
  value = oci_core_subnet.postgresql_subnet.id
}

# PostgreSQL
output "psql_configuration_id" { value = oci_psql_configuration.psql_config.id }
output "db_system_id" { value = oci_psql_db_system.postgresql_db_system.id }
output "db_system_display_name" { value = oci_psql_db_system.postgresql_db_system.display_name }
output "state" { value = oci_psql_db_system.postgresql_db_system.state }
output "primary_endpoint_private_ip" { value = var.primary_db_endpoint_private_ip }

# OpenVPN
output "vpn_public_ip" {
  value       = oci_core_instance.vpn.public_ip
  description = "IP público efêmero para conectar ao OpenVPN (remote no .ovpn)"
}

output "vpn_subnet_id" { value = oci_core_subnet.vpn_subnet.id }

output "ssh_connect" {
  value       = "ssh ubuntu@${oci_core_instance.vpn.public_ip}"
  description = "SSH na instância OpenVPN"
}
