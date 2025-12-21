# ========================================
# Provider Configuration
# ========================================
variable "oci_region" {
  description = "OCI region identifier (e.g., sa-saopaulo-1)"
  type        = string
  validation {
    condition     = var.oci_region != ""
    error_message = "OCI region must be provided."
  }
}

variable "oci_config_profile" {
  description = "OCI config profile name from ~/.oci/config"
  type        = string
  default     = "DEFAULT"
}

# ========================================
# Compartment Configuration
# ========================================
variable "compartment_id" {
  description = "OCID of the compartment where the bucket will be created"
  type        = string
  validation {
    condition     = can(regex("^ocid1.compartment.oc1", var.compartment_id)) || var.compartment_id == ""
    error_message = "Compartment OCID must be a valid OCID format or empty string."
  }
}

# ========================================
# Bucket Configuration
# ========================================
variable "bucket_name" {
  description = "Name of the object storage bucket"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 1 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be 1-63 characters, lowercase alphanumeric with hyphens, and cannot start/end with hyphen."
  }
}

variable "bucket_namespace" {
  description = "Object storage namespace. If not provided, will be automatically fetched using data source."
  type        = string
  default     = null
}

variable "bucket_config" {
  description = "Bucket configuration settings"
  type = object({
    access_type           = optional(string, "NoPublicAccess")
    auto_tiering          = optional(string, null)
    storage_tier          = optional(string, "Standard")
    versioning            = optional(string, "Disabled")
    object_events_enabled = optional(bool, false)
    metadata              = optional(map(string), {})
    kms_key_id           = optional(string, null)
  })
  default = {}
}

# ========================================
# Retention Rules Configuration
# ========================================
variable "retention_rules" {
  description = "List of retention rules to apply to the bucket"
  type = list(object({
    display_name     = string
    time_amount      = number
    time_unit        = string
    time_rule_locked = optional(string, null)
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.retention_rules : contains(["DAYS", "YEARS"], upper(rule.time_unit))
    ])
    error_message = "Retention rule time_unit must be either 'DAYS' or 'YEARS'."
  }
}

# ========================================
# Tags Configuration
# ========================================
variable "defined_tags" {
  description = "Defined tags to apply to the bucket (namespace.key = value)"
  type        = map(string)
  default     = {}
}

variable "freeform_tags" {
  description = "Freeform tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
