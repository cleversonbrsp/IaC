# ========================================
# PostgreSQL DB System Outputs
# ========================================

output "db_system_id" {
  description = "OCID of the PostgreSQL DB System"
  value       = oci_psql_db_system.postgresql_db_system.id
}

output "db_system_display_name" {
  description = "Display name of the PostgreSQL DB System"
  value       = oci_psql_db_system.postgresql_db_system.display_name
}

output "db_system_state" {
  description = "Current state of the PostgreSQL DB System"
  value       = oci_psql_db_system.postgresql_db_system.lifecycle_state
}

output "db_system_primary_endpoint_ip" {
  description = "Primary database endpoint IP address"
  value       = oci_psql_db_system.postgresql_db_system.primary_endpoint_ip
}

output "db_system_primary_endpoint_hostname" {
  description = "Primary database endpoint hostname"
  value       = oci_psql_db_system.postgresql_db_system.primary_endpoint_hostname
}

output "db_system_reader_endpoint_ip" {
  description = "Reader endpoint IP address (if enabled)"
  value       = oci_psql_db_system.postgresql_db_system.reader_endpoint_ip
}

output "db_system_reader_endpoint_hostname" {
  description = "Reader endpoint hostname (if enabled)"
  value       = oci_psql_db_system.postgresql_db_system.reader_endpoint_hostname
}

