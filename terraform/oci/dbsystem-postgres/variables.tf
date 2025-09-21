# OCI Provider Configuration
variable "oci_region" {
  description = "OCI region where resources will be created"
  type        = string
}

variable "oci_config_profile" {
  description = "OCI config profile to use for authentication"
  type        = string
  default     = "DEFAULT"
}

# Compartment Configuration
variable "compartment_id" {
  description = "OCID of the compartment where resources will be created"
  type        = string
}

variable "create_compartment" {
  description = "Whether to create a new compartment or use existing one"
  type        = bool
  default     = false
}

variable "compartment_name" {
  description = "Name of the compartment (used when creating new compartment)"
  type        = string
  default     = "postgres-compartment"
}

variable "compartment_description" {
  description = "Description of the compartment"
  type        = string
  default     = "Compartment for PostgreSQL Database System"
}

# Network Configuration
variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vcn_name" {
  description = "Name of the VCN"
  type        = string
  default     = "postgres-vcn"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# PostgreSQL Database Configuration
variable "db_system_display_name" {
  description = "Display name for the PostgreSQL DB System"
  type        = string
}

variable "db_system_description" {
  description = "Description for the PostgreSQL DB System"
  type        = string
  default     = "PostgreSQL Database System"
}

variable "db_system_shape" {
  description = "Shape for the PostgreSQL DB System"
  type        = string
  default     = "PostgreSQL.VM.Standard.E4.Flex"
}

variable "instance_ocpu_count" {
  description = "Number of OCPUs for the DB System"
  type        = number
  default     = 2
}

variable "instance_memory_size_in_gbs" {
  description = "Memory size in GBs for the DB System"
  type        = number
  default     = 32
}

variable "instance_count" {
  description = "Number of instances in the DB System"
  type        = number
  default     = 1
}

variable "db_version" {
  description = "PostgreSQL database version"
  type        = string
  default     = "14"
}

variable "availability_domain" {
  description = "Availability domain for the DB System"
  type        = string
}

# Storage Configuration
variable "storage_is_regionally_durable" {
  description = "Whether storage is regionally durable"
  type        = bool
  default     = false
}

variable "storage_system_type" {
  description = "Storage system type"
  type        = string
  default     = "OCI_OPTIMIZED_STORAGE"
}

variable "storage_iops" {
  description = "Storage IOPS"
  type        = string
  default     = "75000"
}

# Backup and Maintenance Configuration
variable "maintenance_window_start" {
  description = "Maintenance window start time"
  type        = string
  default     = "SAT 08:00"
}

variable "backup_start_time" {
  description = "Backup start time"
  type        = string
  default     = "00:00"
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_kind" {
  description = "Backup kind (DAILY, WEEKLY, MONTHLY)"
  type        = string
  default     = "WEEKLY"

  validation {
    condition     = contains(["DAILY", "WEEKLY", "MONTHLY"], var.backup_kind)
    error_message = "Backup kind must be one of: DAILY, WEEKLY, MONTHLY."
  }
}

variable "backup_days_of_week" {
  description = "Days of the week for backup (for WEEKLY backup)"
  type        = list(string)
  default     = ["SUNDAY"]
}

variable "backup_days_of_month" {
  description = "Days of the month for backup (for MONTHLY backup)"
  type        = list(number)
  default     = [1]
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key for bastion session access"
  type        = string
  default     = ""
}

# Bastion Configuration
variable "create_bastion_session" {
  description = "Whether to create a bastion session for PostgreSQL access"
  type        = bool
  default     = false
}

variable "bastion_session_ttl" {
  description = "Bastion session TTL in seconds (max 10800 = 3 hours)"
  type        = number
  default     = 10800

  validation {
    condition     = var.bastion_session_ttl <= 10800
    error_message = "Bastion session TTL cannot exceed 10800 seconds (3 hours)."
  }
}

# Database Credentials
variable "db_admin_username" {
  description = "Admin username for PostgreSQL database"
  type        = string
  default     = "postgres"
}

variable "db_admin_password" {
  description = "Admin password for PostgreSQL database (minimum 12 characters)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_admin_password) >= 12
    error_message = "Database admin password must be at least 12 characters long."
  }
}

# Tagging
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (dev, hml, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "postgres"
}