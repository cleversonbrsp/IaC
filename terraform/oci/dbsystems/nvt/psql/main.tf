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

# Região onde os recursos (VCN, compute, DB) serão criados
provider "oci" {
  config_file_profile = var.oci_config_profile
  region              = var.oci_region
}

# Home region do tenancy: Identity (compartments) só aceita CREATE/UPDATE/DELETE na home region
provider "oci" {
  alias               = "home"
  config_file_profile = var.oci_config_profile
  region              = var.home_region
}

# Aguarda propagação do compartment na região (evita 404 ao criar VCN/Psql em região não-home)
resource "time_sleep" "wait_compartment_propagation" {
  create_duration = "90s"
  depends_on      = [oci_identity_compartment.psql_hot_cold_lab]
}

locals {
  compartment_id = coalesce(var.compartment_id, oci_identity_compartment.psql_hot_cold_lab.id)
}
