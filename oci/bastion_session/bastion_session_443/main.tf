terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "~>5.23.0"
    }
  }
}

provider "oci" {
    tenancy_ocid = var.novamerica_tenancy
    user_ocid = var.rackware_user
    private_key_path = var.rackware_api_privatekey
    fingerprint = var.rackware_api_fingerprint
    region = var.sp_region
}