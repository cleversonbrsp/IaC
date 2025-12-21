terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~>7.27.0"
    }
  }
}

provider "oci" {
  config_file_profile = var.oci_config_profile
  region              = var.oci_region
}

