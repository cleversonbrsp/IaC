variable "oci_region" {
  description = "OCI region where resources will be created"
  type        = string
  default     = ""
}

variable "oci_config_profile" {
  description = "OCI config profile name in ~/.oci/config"
  type        = string
  default     = ""
}

variable "comp_id" {
  description = "Compartment OCID where resources will be created"
  type        = string
  default     = ""
}

variable "compartment_id" {
  description = "Legacy variable name for compartment OCID. Prefer comp_id."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type = object({
    defined_tags = map(string)
  })
  default = {
    defined_tags = {}
  }
}

# PostgreSQL DB System Variables
variable "db_system_display_name" {
  description = "Display name for the PostgreSQL DB System"
  type        = string
}

variable "db_system_description" {
  description = "Description for the PostgreSQL DB System"
  type        = string
  default     = ""
}

variable "db_system_config_id" {
  description = "OCID of the PostgreSQL configuration to use"
  type        = string
}

variable "db_version" {
  description = "PostgreSQL database version"
  type        = string
  default     = "14"
}

variable "instance_count" {
  description = "Number of database instances"
  type        = number
  default     = 1
}

variable "instance_memory_size_in_gbs" {
  description = "Memory size in GBs for each database instance"
  type        = number
  default     = 32
}

variable "instance_ocpu_count" {
  description = "Number of OCPUs for each database instance"
  type        = number
  default     = 2
}

variable "db_system_shape" {
  description = "Shape for the PostgreSQL DB System"
  type        = string
  default     = "PostgreSQL.VM.Standard.E4.Flex"
}

variable "system_type" {
  description = "System type for the PostgreSQL DB System"
  type        = string
  default     = "OCI_OPTIMIZED_STORAGE"
}

# Management Policy Variables
variable "maintenance_window_start" {
  description = "Maintenance window start time (e.g., 'MON 12:30')"
  type        = string
  default     = "MON 12:30"
}

variable "backup_start" {
  description = "Backup start time (e.g., '00:00')"
  type        = string
  default     = "00:00"
}

variable "backup_days_of_the_month" {
  description = "Days of the month for backup schedule"
  type        = list(number)
  default     = [1]
}

variable "backup_days_of_the_week" {
  description = "Days of the week for backup schedule"
  type        = list(string)
  default     = ["MONDAY"]
}

variable "backup_kind" {
  description = "Backup schedule kind (WEEKLY, MONTHLY)"
  type        = string
  default     = "WEEKLY"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# Network Variables
variable "create_network_resources" {
  description = "Whether to create VCN, subnet, and NSG resources"
  type        = bool
  default     = false
}

variable "vcn_cidr_block" {
  description = "CIDR block for the VCN (required if create_network_resources is true)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vcn_display_name" {
  description = "Display name for the VCN"
  type        = string
  default     = "postgresql-vcn"
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN"
  type        = string
  default     = "postgresqlvcn"
}

variable "subnet_cidr_block" {
  description = "CIDR block for the subnet (required if create_network_resources is true)"
  type        = string
  default     = "10.0.10.0/24"
}

variable "subnet_display_name" {
  description = "Display name for the subnet"
  type        = string
  default     = "postgresql-subnet"
}

variable "subnet_dns_label" {
  description = "DNS label for the subnet"
  type        = string
  default     = "postgresqlsubnet"
}

variable "subnet_prohibit_public_ip" {
  description = "Whether to prohibit public IP on VNIC (true for private subnet)"
  type        = bool
  default     = true
}

variable "nsg_display_name" {
  description = "Display name for the Network Security Group"
  type        = string
  default     = "postgresql-nsg"
}

variable "primary_db_endpoint_private_ip" {
  description = "Private IP address for the primary database endpoint"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet for the DB System (required if create_network_resources is false)"
  type        = string
  default     = ""
}

variable "nsg_ids" {
  description = "List of NSG OCIDs to attach to the DB System (required if create_network_resources is false)"
  type        = list(string)
  default     = []
}

variable "is_reader_endpoint_enabled" {
  description = "Whether to enable reader endpoint"
  type        = bool
  default     = false
}

# Database Credentials Variables (for new database deployments)
variable "db_username" {
  description = "Database administrator username (required for new database, source_type = NONE)"
  type        = string
  default     = ""
  sensitive   = false
}

variable "db_password" {
  description = "Database administrator password (required if db_password_secret_id is not provided and source_type = NONE)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_password_secret_id" {
  description = "OCID of the OCI Vault secret containing the database password (preferred over plain text password)"
  type        = string
  default     = ""
}

# Source Variables (for restore from backup)
variable "source_type" {
  description = "Source type for the DB System (NONE for new database, BACKUP for restore)"
  type        = string
  default     = "NONE"
}

variable "backup_id" {
  description = "OCID of the backup to restore from (required if source_type is BACKUP)"
  type        = string
  default     = ""
}

variable "is_having_restore_config_overrides" {
  description = "Whether to have restore config overrides"
  type        = bool
  default     = false
}

# Storage Variables
variable "availability_domain" {
  description = "Availability Domain for storage (e.g., 'giZW:US-ASHBURN-AD-1')"
  type        = string
}

variable "storage_iops" {
  description = "IOPS for storage"
  type        = string
  default     = "75000"
}

variable "is_regionally_durable" {
  description = "Whether storage is regionally durable"
  type        = bool
  default     = false
}

