# Configuração do PostgreSQL (shape, versão, overrides). Usada pelo DB system (psql.tf).
resource "oci_psql_configuration" "psql_config" {
  compartment_id = local.compartment_id
  db_version     = var.db_version
  display_name   = "psql-hot-cold-lab-config"

  db_configuration_overrides {
    items {
      config_key             = "log_connections"
      overriden_config_value = "1"
    }
  }

  shape                       = "VM.Standard.E5.Flex"
  instance_memory_size_in_gbs = var.instance_memory_size_in_gbs
  instance_ocpu_count         = var.instance_ocpu_count
  defined_tags                = var.common_tags.defined_tags
}
