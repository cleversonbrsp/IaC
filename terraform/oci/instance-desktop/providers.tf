provider "oci" {
  config_file_profile = var.oci_config_profile
  region              = var.oci_region
}

# Identity (compartment) só na HOME region da tenancy.
provider "oci" {
  alias               = "home"
  config_file_profile = var.oci_config_profile
  region              = var.oci_home_region
}
