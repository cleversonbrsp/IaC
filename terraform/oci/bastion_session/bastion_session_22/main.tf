terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "~>6.23.0"
    }
  }
}

provider "oci" {
    # tenancy_ocid = var.root_tenancy
    # user_ocid = var.oci_user
    # private_key_path = var.api_private_key
    # fingerprint = var.api_fingerprint
    region = "us-ashburn-1"
}