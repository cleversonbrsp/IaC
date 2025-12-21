# ========================================
# VARIABLES FOR USAGE2ADW TERRAFORM STACK
# ========================================
# Baseado no oracle-samples/usage-reports-to-adw terraform/variables.tf

# ========================================
# REQUIRED - OCI IDENTIFIERS
# ========================================
variable "tenancy_ocid" {
  description = "OCID do Tenancy"
  type        = string
}

variable "region" {
  description = "Região OCI (deve ser Home Region)"
  type        = string
}

variable "oci_config_profile" {
  description = "Perfil OCI configurado em ~/.oci/config"
  type        = string
  default     = "devopsguide"
}

variable "compartment_ocid" {
  description = "OCID do Compartment onde criar recursos"
  type        = string
}

# ========================================
# OPTIONAL - TAGS
# ========================================
variable "service_tags" {
  type = object({
    freeformTags = map(string)
    definedTags  = map(string)
  })
  description = "Tags to be applied to all resources created by Usage2ADW stack"
  default     = { freeformTags = {}, definedTags = {} }
}

# ========================================
# IAM CONFIGURATION
# ========================================
variable "option_iam" {
  description = "IAM option: 'New IAM Dynamic Group and Policy will be created' or 'I have already created Dynamic Group and Policy per the documentation'"
  type        = string
}

variable "new_policy_name" {
  description = "Nome da política IAM a ser criada"
  type        = string
  default     = ""
}

variable "new_dynamic_group_name" {
  description = "Nome do Dynamic Group a ser criado"
  type        = string
  default     = ""
}

# ========================================
# LOAD BALANCER CONFIGURATION
# ========================================
variable "option_loadbalancer" {
  description = "Load Balancer option: 'Provision Public Load Balancer' or 'Do Not Provision Public Load Balancer'"
  type        = string
  default     = "Do Not Provision Public Load Balancer"
}

variable "loadbalancer_name" {
  description = "Nome do Load Balancer"
  type        = string
  default     = ""
}

variable "db_network_nsg_name" {
  description = "Nome do Network Security Group para ADW Private Endpoint"
  type        = string
  default     = ""
}

# ========================================
# AUTONOMOUS DATABASE CONFIGURATION
# ========================================
variable "option_autonomous_database" {
  description = "ADB deployment option: 'Public Endpoint' or 'Private Endpoint'"
  type        = string
}

variable "db_db_name" {
  description = "Nome do Autonomous Database"
  type        = string
  default     = ""
}

variable "db_secret_compartment_id" {
  description = "OCID do Compartment onde está o Vault Secret"
  type        = string
  default     = ""
}

variable "db_secret_id" {
  description = "OCID do Vault Secret com senha do ADW"
  type        = string
  default     = ""
}

variable "db_license_model" {
  description = "Modelo de licença do ADW: 'LICENSE_INCLUDED' ou 'BRING_YOUR_OWN_LICENSE'"
  type        = string
  default     = ""
}

variable "db_private_end_point_label" {
  description = "Label do Private Endpoint do ADW"
  type        = string
  default     = ""
}

# ========================================
# COMPUTE INSTANCE CONFIGURATION
# ========================================
variable "ssh_public_key" {
  description = "Chave SSH pública para acesso à VM"
  type        = string
  default     = ""
}

variable "instance_shape" {
  description = "Shape da instância compute"
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Nome da instância compute"
  type        = string
  default     = ""
}

variable "instance_availability_domain" {
  description = "Availability Domain para a instância"
  type        = string
  default     = ""
}

# ========================================
# USAGE REPORTS EXTRACTION CONFIGURATION
# ========================================
variable "extract_from_date" {
  description = "Data de início da extração (formato YYYY-MM)"
  type        = string
  default     = ""
}

variable "extract_tag1_special_key" {
  description = "Tag especial 1 para relatórios"
  type        = string
  default     = ""
}

variable "extract_tag2_special_key" {
  description = "Tag especial 2 para relatórios"
  type        = string
  default     = ""
}

variable "extract_tag3_special_key" {
  description = "Tag especial 3 para relatórios"
  type        = string
  default     = ""
}

variable "extract_tag4_special_key" {
  description = "Tag especial 4 para relatórios"
  type        = string
  default     = ""
}

# ========================================
# ORACLE ANALYTICS CLOUD (OPCIONAL)
# ========================================
variable "option_oac" {
  description = "OAC option: 'Deploy Oracle Analytics Cloud' or 'Do Not Deploy Oracle Analytics Cloud'"
  type        = string
  default     = "Do Not Deploy Oracle Analytics Cloud"
}

variable "analytics_instance_name" {
  description = "Nome da instância OAC"
  type        = string
  default     = ""
}

variable "analytics_instance_capacity_value" {
  description = "Capacidade da instância OAC"
  type        = string
  default     = ""
}

variable "analytics_instance_feature_set" {
  description = "Feature set do OAC: 'OAC Enterprise Edition' ou 'OAC Standard Edition'"
  type        = string
  default     = ""
}

variable "analytics_instance_license_type" {
  description = "Tipo de licença do OAC"
  type        = string
  default     = ""
}

variable "analytics_instance_idcs_access_token" {
  description = "IDCS Access Token para OAC"
  type        = string
  default     = ""
}