# 4 - DB systems PostgreSQL (após configuration e redes, inclusive VPN)

# DBSystem HOT
resource "oci_psql_db_system" "postgresql_db_system" {
  display_name   = var.db_system_display_name
  description    = coalesce(var.db_system_description, var.db_system_display_name)
  compartment_id = local.compartment_id
  config_id      = coalesce(var.db_system_config_id, oci_psql_configuration.psql_config.id)
  db_version     = var.db_version
  defined_tags   = var.common_tags.defined_tags

  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]
  }

  instance_count              = var.instance_count
  instance_memory_size_in_gbs = var.instance_memory_size_in_gbs
  instance_ocpu_count         = var.instance_ocpu_count
  shape                       = var.db_system_shape
  system_type                 = var.system_type

  management_policy {
    maintenance_window_start = var.maintenance_window_start
    backup_policy {
      backup_start      = var.backup_start
      days_of_the_month = var.backup_days_of_the_month
      days_of_the_week  = var.backup_days_of_the_week
      kind              = var.backup_kind
      retention_days    = var.backup_retention_days
    }
  }

  network_details {
    is_reader_endpoint_enabled     = var.is_reader_endpoint_enabled
    nsg_ids                        = [oci_core_network_security_group.postgresql_nsg.id]
    primary_db_endpoint_private_ip = var.primary_db_endpoint_private_ip
    subnet_id                      = oci_core_subnet.postgresql_subnet.id
  }

  dynamic "credentials" {
    for_each = var.source_type == "NONE" && var.db_username != "" ? [1] : []
    content {
      username = var.db_username
      password_details {
        password_type = var.db_password_secret_id != "" ? "VAULT_SECRET" : "PLAIN_TEXT"
        password      = var.db_password_secret_id != "" ? null : var.db_password
        secret_id     = var.db_password_secret_id != "" ? var.db_password_secret_id : null
      }
    }
  }

  dynamic "source" {
    for_each = var.source_type == "BACKUP" ? [1] : []
    content {
      backup_id                          = var.backup_id
      is_having_restore_config_overrides = var.is_having_restore_config_overrides
      source_type                        = var.source_type
    }
  }

  storage_details {
    availability_domain   = var.availability_domain
    iops                  = var.storage_iops
    is_regionally_durable = var.is_regionally_durable
    system_type           = var.system_type
  }

  depends_on = [oci_core_subnet.vpn_subnet]
}

# DBSystem COLD (opcional; controlado por create_cold_db_system)
resource "oci_psql_db_system" "postgresql_db_system_cold" {
  count = var.create_cold_db_system ? 1 : 0

  display_name   = coalesce(var.cold_db_system_display_name, "pg-cold-archive")
  description    = coalesce(var.cold_db_system_description, "COLD - ${coalesce(var.db_system_description, var.db_system_display_name)}")
  compartment_id = local.compartment_id
  config_id      = coalesce(var.db_system_config_id, oci_psql_configuration.psql_config.id)
  db_version     = var.db_version
  defined_tags   = var.common_tags.defined_tags

  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]
  }

  instance_count              = var.instance_count
  instance_memory_size_in_gbs = var.cold_instance_memory_size_in_gbs != 0 ? var.cold_instance_memory_size_in_gbs : var.instance_memory_size_in_gbs
  instance_ocpu_count         = var.cold_instance_ocpu_count != 0 ? var.cold_instance_ocpu_count : var.instance_ocpu_count
  shape                       = var.db_system_shape
  system_type                 = var.system_type

  management_policy {
    maintenance_window_start = var.maintenance_window_start
    backup_policy {
      backup_start      = var.backup_start
      days_of_the_month = var.backup_days_of_the_month
      days_of_the_week  = var.backup_days_of_the_week
      kind              = var.cold_backup_kind != "" ? var.cold_backup_kind : var.backup_kind
      retention_days    = var.cold_backup_retention_days != 0 ? var.cold_backup_retention_days : var.backup_retention_days
    }
  }

  network_details {
    is_reader_endpoint_enabled     = var.is_reader_endpoint_enabled
    nsg_ids                        = [oci_core_network_security_group.postgresql_nsg.id]
    primary_db_endpoint_private_ip = var.cold_primary_db_endpoint_private_ip
    subnet_id                      = oci_core_subnet.postgresql_subnet.id
  }

  dynamic "credentials" {
    for_each = var.source_type == "NONE" && var.db_username != "" ? [1] : []
    content {
      username = var.db_username
      password_details {
        password_type = var.db_password_secret_id != "" ? "VAULT_SECRET" : "PLAIN_TEXT"
        password      = var.db_password_secret_id != "" ? null : var.db_password
        secret_id     = var.db_password_secret_id != "" ? var.db_password_secret_id : null
      }
    }
  }

  dynamic "source" {
    for_each = var.source_type == "BACKUP" ? [1] : []
    content {
      backup_id                          = var.backup_id
      is_having_restore_config_overrides = var.is_having_restore_config_overrides
      source_type                        = var.source_type
    }
  }

  storage_details {
    availability_domain   = var.availability_domain
    iops                  = var.storage_iops
    is_regionally_durable = var.is_regionally_durable
    system_type           = var.system_type
  }

  depends_on = [oci_core_subnet.vpn_subnet]
}
