# --- Provider / comum ---
variable "oci_region" {
  type        = string
  description = "Região onde criar VCN, subnets, DB systems, instâncias (ex.: us-ashburn-1)"
  default     = ""
}

variable "home_region" {
  type        = string
  description = "Home region do tenancy; Identity (compartments) só aceita operações aqui (ex.: sa-saopaulo-1 para GRU)"
  default     = "sa-saopaulo-1"
}

variable "oci_config_profile" {
  type    = string
  default = ""
}

variable "parent_compartment_id" {
  type        = string
  description = "OCID do compartment pai onde psql_hot_cold_lab será criado"
  default     = ""
}

variable "compartment_id" {
  type        = string
  description = "OCID do compartment (default: o compartment criado)"
  default     = null
}

variable "common_tags" {
  type    = object({ defined_tags = map(string) })
  default = { defined_tags = {} }
}

# --- Compartment / DB System / Configuration ---
variable "db_system_display_name" {
  type    = string
  default = ""
}
variable "db_system_description" {
  type    = string
  default = ""
}
variable "db_system_config_id" {
  type    = string
  default = null
}
variable "db_version" {
  type    = string
  default = ""
}
variable "instance_count" {
  type    = number
  default = 0
}
variable "instance_memory_size_in_gbs" {
  type    = number
  default = 0
}
variable "instance_ocpu_count" {
  type    = number
  default = 0
}
variable "db_system_shape" {
  type    = string
  default = ""
}
variable "system_type" {
  type    = string
  default = ""
}

variable "maintenance_window_start" {
  type    = string
  default = ""
}
variable "backup_start" {
  type    = string
  default = ""
}
variable "backup_days_of_the_month" {
  type    = list(number)
  default = []
}
variable "backup_days_of_the_week" {
  type    = list(string)
  default = []
}
variable "backup_kind" {
  type    = string
  default = ""
}
variable "backup_retention_days" {
  type    = number
  default = 0
}

# --- DB System COLD (override de configuração do HOT) ---
variable "cold_db_system_display_name" {
  type    = string
  default = ""
}
variable "cold_db_system_description" {
  type    = string
  default = ""
}
variable "cold_instance_memory_size_in_gbs" {
  type    = number
  default = 0
}
variable "cold_instance_ocpu_count" {
  type    = number
  default = 0
}
variable "cold_backup_kind" {
  type    = string
  default = ""
}
variable "cold_backup_retention_days" {
  type    = number
  default = 0
}
variable "cold_primary_db_endpoint_private_ip" {
  type        = string
  description = "IP privado do endpoint primário do DBSystem COLD"
  default     = ""
}

variable "vcn_cidr_block" {
  type    = string
  default = ""
}
variable "vcn_display_name" {
  type    = string
  default = ""
}
variable "vcn_dns_label" {
  type    = string
  default = ""
}
variable "subnet_cidr_block" {
  type    = string
  default = ""
}
variable "subnet_display_name" {
  type    = string
  default = ""
}
variable "subnet_dns_label" {
  type    = string
  default = ""
}
variable "nsg_display_name" {
  type    = string
  default = ""
}

variable "primary_db_endpoint_private_ip" {
  type        = string
  description = "IP privado do endpoint primário (dentro do subnet_cidr_block)"
  default     = ""
}

variable "is_reader_endpoint_enabled" {
  type    = bool
  default = false
}

variable "db_username" {
  type    = string
  default = ""
}
variable "db_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "db_password_secret_id" {
  type    = string
  default = ""
}

variable "source_type" {
  type    = string
  default = ""
}
variable "backup_id" {
  type    = string
  default = ""
}
variable "is_having_restore_config_overrides" {
  type    = bool
  default = false
}

variable "availability_domain" {
  type        = string
  description = "Availability Domain (ex.: YCyV:SA-SAOPAULO-1-AD-1)"
  default     = ""
}

variable "storage_iops" {
  type    = string
  default = ""
}
variable "is_regionally_durable" {
  type    = bool
  default = false
}

# --- OpenVPN ---
variable "ssh_public_key_path" {
  type        = string
  description = "Caminho da chave SSH pública para a instância OpenVPN"
  default     = ""
}

variable "ssh_private_key_path" {
  type        = string
  description = "Opcional; reservado para uso em scripts."
  default     = ""
}

variable "image_id" {
  type        = string
  description = "OCID da imagem Ubuntu para a instância OpenVPN"
  default     = ""
}

variable "vpn_subnet_cidr" {
  type    = string
  default = ""
}
variable "db_subnet_cidr" {
  type    = string
  default = ""
}
variable "openvpn_port" {
  type    = number
  default = 0
}
variable "instance_display_name" {
  type    = string
  default = ""
}
variable "instance_shape" {
  type    = string
  default = ""
}
variable "instance_memory_gb" {
  type    = number
  default = 0
}
variable "instance_ocpus" {
  type    = number
  default = 0
}
variable "ssh_allowed_cidr" {
  type    = string
  default = ""
}
