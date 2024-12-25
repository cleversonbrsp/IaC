terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~>6.17.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.oci_root_tenancy
  user_ocid        = var.oci_user
  private_key_path = var.oci_apikey
  fingerprint      = var.oci_fringerprint
  region           = var.oci_region
}