# Data source for PostgreSQL default configuration
data "oci_psql_default_configurations" "postgres_default_configs" {
  filter {
    name   = "db_version"
    values = [var.db_version]
  }
}

# PostgreSQL Database System
resource "oci_psql_db_system" "postgres_db_system" {
  compartment_id              = local.compartment_id
  display_name                = local.db_system_name
  description                 = var.db_system_description
  shape                       = var.db_system_shape
  instance_ocpu_count         = var.instance_ocpu_count
  instance_memory_size_in_gbs = var.instance_memory_size_in_gbs
  instance_count              = var.instance_count
  db_version                  = var.db_version

  # Use the first available default configuration for the specified DB version
  config_id = data.oci_psql_default_configurations.postgres_default_configs.default_configuration_collection[0].items[0].id

  # Database credentials
  credentials {
    username = var.db_admin_username
    password_details {
      password_type = "PLAIN_TEXT"
      password      = var.db_admin_password
    }
  }

  network_details {
    subnet_id = oci_core_subnet.postgres_private_subnet.id
    nsg_ids   = [oci_core_network_security_group.postgres_nsg.id]
  }

  storage_details {
    is_regionally_durable = var.storage_is_regionally_durable
    system_type           = var.storage_system_type
    availability_domain   = local.ad_name
    iops                  = var.storage_iops
  }

  management_policy {
    maintenance_window_start = var.maintenance_window_start

    backup_policy {
      backup_start      = var.backup_start_time
      days_of_the_month = var.backup_days_of_month
      days_of_the_week  = var.backup_days_of_week
      kind              = var.backup_kind
      retention_days    = var.backup_retention_days
    }
  }


  depends_on = [
    oci_core_subnet.postgres_private_subnet,
    oci_core_network_security_group.postgres_nsg
  ]
}