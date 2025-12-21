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
  description = "Legacy/compatible variable name for compartment OCID"
  type        = string
  default     = ""
}

# ========================================
# VCN Configuration
# ========================================
variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vcn_display_name" {
  description = "Display name for the VCN"
  type        = string
  default     = "nvt-infra-vcn"
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN"
  type        = string
  default     = "nvtinfravcn"
}

# ========================================
# Subnet Configuration
# ========================================
variable "vpn_subnet_cidr" {
  description = "CIDR block for VPN subnet"
  type        = string
  default     = "10.0.30.0/24"
}

variable "oke_api_subnet_cidr" {
  description = "CIDR block for OKE API endpoint subnet"
  type        = string
  default     = "10.0.0.0/28"
}

variable "oke_node_subnet_cidr" {
  description = "CIDR block for OKE node subnet"
  type        = string
  default     = "10.0.10.0/24"
}

variable "oke_lb_subnet_cidr" {
  description = "CIDR block for OKE load balancer subnet"
  type        = string
  default     = "10.0.20.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR block for database subnet"
  type        = string
  default     = "10.0.40.0/24"
}

# ========================================
# Tags Configuration
# ========================================
variable "defined_tags" {
  description = "Defined tags to apply to resources"
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

