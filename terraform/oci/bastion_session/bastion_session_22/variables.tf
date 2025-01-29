variable "root_tenancy" {
  default = ""
}
variable "oci_user" {
  default = ""
}
variable "api_private_key" {
  default = ""
}
variable "api_fingerprint" {
  default = ""
}
variable "oci_main_region" {
  default = ""
}

variable "bastion_ocid" {
  default = ""
}

variable "ssh_bastion_key" {
  default = ""
  type = string
}

variable "target_ocid" {
  default = ""
}

variable "nvt_cloud_prod_comp" {
  default = ""
}

variable "subnet_pvt2" {
  default = ""
}

variable "instance_user" {
  default = ""
}

variable "block_allow_list" {
  default = ""
}

variable "bastion_type" {
  default = ""
}

variable "bastion_name" {
  default = ""
}

variable "session_type" {
  default = ""
}

variable "target_resource_port" {
  default = ""
}

variable "target_resource_instance" {
  default = ""
}