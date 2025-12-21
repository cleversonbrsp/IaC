# ========================================
# AUTONOMOUS DATABASE MODULE
# ========================================
# Usa o módulo upstream para criar o ADW
# Baseado no oracle-samples/usage-reports-to-adw

module "adb" {
  source = "/home/cleverson/Documents/github/usage-reports-to-adw/terraform/modules/adb"

  compartment_id          = var.compartment_ocid
  db_secret_id            = var.db_secret_id
  db_name                 = var.db_db_name
  license_model           = var.db_license_model
  nsg_id                  = module.network_upstream.nsg_id              # NSG do módulo upstream
  subnet_id               = oci_core_subnet.usage2adw_private_subnet.id # Subnet privada local
  private_end_point_label = var.db_private_end_point_label
  service_tags            = var.service_tags
  autonomous_pe_enabled   = var.option_autonomous_database == "Private Endpoint" ? true : false
}

# ========================================
# ADB OUTPUTS
# ========================================
output "apex_url" {
  description = "URL do APEX"
  value       = module.adb.apex_url
}

output "adwc_id" {
  description = "OCID do Autonomous Database"
  value       = module.adb.adwc_id
}

output "adwc_pe_ip" {
  description = "IP do Private Endpoint do ADW"
  value       = module.adb.adwc_pe_ip
}

output "adwc_console" {
  description = "URL do Service Console do ADW"
  value       = module.adb.adwc_console
}