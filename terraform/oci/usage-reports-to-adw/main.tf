# ========================================
# USAGE2ADW MAIN ORCHESTRATION
# ========================================
# Orquestra todos os módulos do projeto Usage2ADW
# Baseado no oracle-samples/usage-reports-to-adw

# ========================================
# NETWORK MODULE (UPSTREAM)
# ========================================
module "network_upstream" {
  source                     = "/home/cleverson/Documents/github/usage-reports-to-adw/terraform/modules/network"
  compartment_id             = var.compartment_ocid
  network_nsg_name           = var.db_network_nsg_name
  existing_vcn_id            = module.vcn.vcn_id # Usar VCN criada localmente
  service_tags               = var.service_tags
  load_balancer_display_name = var.loadbalancer_name
  load_balancer_subnet_id    = oci_core_subnet.usage2adw_public_subnet.id # Usar subnet pública local
  adw_pe_ip_address          = module.adb.adwc_pe_ip
  load_balancer_enabled      = var.option_loadbalancer == "Provision Public Load Balancer" ? true : false
  autonomous_pe_enabled      = var.option_autonomous_database == "Private Endpoint" ? true : false
}

# ========================================
# COMPUTE MODULE (UPSTREAM)
# ========================================
module "compute" {
  source              = "/home/cleverson/Documents/github/usage-reports-to-adw/terraform/modules/compute"
  region              = var.region
  compartment_id      = var.compartment_ocid
  availability_domain = var.instance_availability_domain
  instance_name       = var.instance_name
  ssh_authorized_keys = var.ssh_public_key
  shape               = var.instance_shape
  subnet_id           = oci_core_subnet.usage2adw_private_subnet.id # Usar subnet privada local
  db_db_name          = var.db_db_name
  db_db_id            = module.adb.adwc_id

  db_secret_id             = var.db_secret_id
  tenancy_ocid             = var.tenancy_ocid
  extract_from_date        = var.extract_from_date
  extract_tag1_special_key = var.extract_tag1_special_key
  extract_tag2_special_key = var.extract_tag2_special_key
  extract_tag3_special_key = var.extract_tag3_special_key
  extract_tag4_special_key = var.extract_tag4_special_key
  service_tags             = var.service_tags

  admin_url          = module.adb.apex_url
  application_url    = replace(module.adb.apex_url, "apex", "f?p=100:LOGIN_DESKTOP::::::")
  lb_application_url = module.network_upstream.load_balancer_ip_address != null ? "https://${module.network_upstream.load_balancer_ip_address}/ords/f?p=100:LOGIN_DESKTOP::::::" : "NA"
  lb_admin_url       = module.network_upstream.load_balancer_ip_address != null ? "https://${module.network_upstream.load_balancer_ip_address}/ords/f?p=4550:1::::::" : "NA"
}

# ========================================
# DEPENDENCIES
# ========================================
# Garantir ordem de criação: VCN -> ADB -> Network (NSG/LB) -> Compute
locals {
  _ordering = [module.adb, module.network_upstream]
}

# ========================================
# MAIN OUTPUTS
# ========================================
output "APEX_Admin_Workspace_URL" {
  description = "URL do APEX Admin Workspace"
  value       = module.adb.apex_url
}

output "APEX_Application_Login_URL" {
  description = "URL de login da aplicação APEX"
  value       = replace(module.adb.apex_url, "apex", "f?p=100:LOGIN_DESKTOP::::::")
}

output "Load_Balancer_Apex_Admin_Workspace" {
  description = "URL do APEX Admin via Load Balancer"
  value       = module.network_upstream.load_balancer_ip_address != null ? "https://${module.network_upstream.load_balancer_ip_address}/ords/f?p=4550:1::::::" : null
}

output "Load_Balancer_Apex_App_Login_URL" {
  description = "URL de login da aplicação APEX via Load Balancer"
  value       = module.network_upstream.load_balancer_ip_address != null ? "https://${module.network_upstream.load_balancer_ip_address}/ords/f?p=100:LOGIN_DESKTOP::::::" : null
}