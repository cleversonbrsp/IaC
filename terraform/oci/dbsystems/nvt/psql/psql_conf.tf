# PostgreSQL configuration (shape, version, overrides). Used by the DB system (psql.tf).
resource "oci_psql_configuration" "psql_config" {
  compartment_id = local.compartment_id
  db_version     = var.db_version
  display_name   = "psql-hot-cold-lab-config"

  depends_on = [time_sleep.wait_compartment_propagation]

  db_configuration_overrides {
    items {
      config_key             = "log_connections"
      overriden_config_value = "1"
    }
  }

  shape                       = "VM.Standard.E5.Flex"
  # E5.Flex requires memory between 16 and 64 GB in the configuration; DB systems may use less in the resource
  instance_memory_size_in_gbs = max(16, var.instance_memory_size_in_gbs, var.cold_instance_memory_size_in_gbs)
  instance_ocpu_count         = max(1, var.instance_ocpu_count, var.cold_instance_ocpu_count)
  defined_tags                = var.common_tags.defined_tags
}
