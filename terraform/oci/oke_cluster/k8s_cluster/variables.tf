variable "oci_user" {
  default = ""
}

variable "oci_fringerprint" {
  default = ""
}

variable "oci_region" {
  default = ""
}

variable "oci_apikey" {
  default = ""
}

variable "oci_root_tenancy" {
  default = ""
}

variable "vcn_cdir_block" {
  default = ""
}

variable "vcn_display_name" {
  default = ""
}

variable "vcn_dns_label" {
  default = ""
}

variable "vcn_igw_display" {
  default = ""
}

variable "lb_cdir_block" {
  default = ""
}

variable "lbsubnet_name" {
  default = ""
}

variable "nodes_cdir_block" {
  default = ""
}

variable "nodes_subnet_name" {
  default = ""
}

variable "api_subnet_cdir_block" {
  default = ""
}

variable "api_subnet_name" {
  default = ""
}

variable "oci_ad" {
  default = ""
}

variable "oci_ad_agak" {
  default = ""
}

variable "node_img" {
  type    = string
  default = ""
}

# variable "kubernetes_host" {
#   type = string
# }

# variable "kubernetes_token" {
#   type      = string
#   sensitive = true
# }

# variable "kubernetes_ca_certificate" {
#   type = string
# }
