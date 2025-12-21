# ========================================
# Data Sources
# ========================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_id
}

