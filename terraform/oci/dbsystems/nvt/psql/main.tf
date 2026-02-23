terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Region where resources (VCN, compute, DB) will be created
provider "oci" {
  config_file_profile = var.oci_config_profile
  region              = var.oci_region
}

# Tenancy home region: Identity (compartments) only accepts CREATE/UPDATE/DELETE in the home region
provider "oci" {
  alias               = "home"
  config_file_profile = var.oci_config_profile
  region              = var.home_region
}

# Wait for compartment propagation across regions (avoids 404 when creating VCN/Psql in non-home region)
resource "time_sleep" "wait_compartment_propagation" {
  create_duration = "90s"
  depends_on      = [oci_identity_compartment.psql_hot_cold_lab]
}

locals {
  compartment_id = coalesce(var.compartment_id, oci_identity_compartment.psql_hot_cold_lab.id)
}
