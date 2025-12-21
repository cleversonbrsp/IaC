# ========================================
# COMMON VARIABLES TEMPLATE
# ========================================
# This file serves as a reference template for common variables
# that should be included in each module's variables.tf file.
#
# Copy these variable definitions into your module's variables.tf
# and customize as needed for module-specific requirements.
#
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
  description = "OCID of the compartment where resources will be created"
  type        = string
  validation {
    condition     = can(regex("^ocid1.compartment.oc1", var.compartment_id)) || var.compartment_id == ""
    error_message = "Compartment OCID must be a valid OCID format or empty string."
  }
}

variable "comp_id" {
  description = "Legacy/compatible variable name for compartment OCID. Prefer compartment_id."
  type        = string
  default     = ""
}

# ========================================
# Tags Configuration
# ========================================
variable "defined_tags" {
  description = "Defined tags to apply to resources (module-specific override)"
  type        = map(string)
  default     = {}
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

