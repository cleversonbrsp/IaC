variable "oci_region" {
  description = "OCI region"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "oci_ad" {
  description = "OCI Availability Domain"
  type        = string
  default     = "agak:SA-SAOPAULO-1-AD-1"
}

variable "ssh_instances_key" {
  description = "SSH public key for instances"
  type        = string
  default     = ""
}

variable "comp_id" {
  description = "Compartment OCID"
  type        = string
  default     = ""
}

variable "instance_shape" {
  description = "Instance shape"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_memory_gb" {
  description = "Instance memory in GB"
  type        = number
  default     = 6
}

variable "instance_ocpus" {
  description = "Instance OCPUs"
  type        = number
  default     = 1
}

variable "vcn_cidr" {
  description = "VCN CIDR block"
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "192.168.0.0/16"
}

variable "fedora-img" {
  default = "https://fedoraproject.org/cloud/download"
}

variable "ubuntu-img" {
  default = "https://cloud-images.ubuntu.com/jammy/current/"
}