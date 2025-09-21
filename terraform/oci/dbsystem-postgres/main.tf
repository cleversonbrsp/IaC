terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~>7.17.0"
    }
  }
}

provider "oci" {
  config_file_profile = "DEFAULT"
  region              = var.oci_region
}