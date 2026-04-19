resource "oci_identity_compartment" "desktop" {
  provider       = oci.home
  compartment_id = var.parent_compartment_id

  name        = var.compartment_name
  description = var.compartment_description

  enable_delete = true
  defined_tags  = var.common_tags.defined_tags
}

resource "time_sleep" "after_compartment" {
  create_duration = var.compartment_propagation_delay
  depends_on      = [oci_identity_compartment.desktop]
}
