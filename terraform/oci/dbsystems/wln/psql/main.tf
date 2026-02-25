terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.2.0"
    }
  }
}

provider "oci" {
  config_file_profile = var.oci_config_profile
  region              = var.oci_region
}

locals {
  compartment_id = coalesce(var.compartment_id, oci_identity_compartment.psql_hot_cold_lab.id)
}
