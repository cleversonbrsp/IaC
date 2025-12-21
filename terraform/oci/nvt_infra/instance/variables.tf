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
# Network Configuration
# ========================================
variable "subnet_id" {
  description = "OCID of the subnet where the VPN instance will be created"
  type        = string
}

variable "availability_domain" {
  description = "Availability Domain for the instance (e.g., FOjF:SA-SAOPAULO-1-AD-1)"
  type        = string
}

# ========================================
# Instance Configuration
# ========================================
variable "instance_display_name" {
  description = "Display name for the VPN instance"
  type        = string
  default     = "nvt-openvpn-instance"
}

variable "instance_shape" {
  description = "Shape for the instance"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_shape_config" {
  description = "Shape configuration (OCPUs and memory)"
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default = {
    ocpus         = 1
    memory_in_gbs = 8
  }
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the instance"
  type        = bool
  default     = true
}

# ========================================
# Image Configuration
# ========================================
variable "image_id" {
  description = "OCID of the image to use for the instance"
  type        = string
}

# ========================================
# SSH Configuration
# ========================================
variable "ssh_authorized_keys" {
  description = "SSH public key for accessing the instance"
  type        = string
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

