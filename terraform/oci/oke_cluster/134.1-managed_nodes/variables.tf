variable "oci_region" {
  default = ""
  type    = string
}

variable "oci_ad" {
  default = ""
  type    = string
}

variable "comp_id" {
  default = ""
  type    = string
}

# variable "ssh_instances_key" {
#   default = ""
#   type    = string
# }

variable "oci_config_profile" {
  default = ""
  type    = string
}

variable "image_id" {
  description = "OCID of the compute image to use for node pools"
  type        = string
  default     = ""
}

# Legacy/compat variables to support imported tfvars
# variable "ssh_public_key" {
#   description = "Path to SSH public key (legacy name). Prefer ssh_instances_key."
#   type        = string
#   default     = ""
# }

variable "compartment_id" {
  description = "Legacy variable name for compartment OCID. Prefer comp_id."
  type        = string
  default     = ""
}

variable "region" {
  description = "Legacy variable name for region. Prefer oci_region."
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
