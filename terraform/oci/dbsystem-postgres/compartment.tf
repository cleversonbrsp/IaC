# Optional compartment creation - only if create_compartment is true
resource "oci_identity_compartment" "postgres" {
  count = var.create_compartment ? 1 : 0

  compartment_id = var.compartment_id
  description    = var.compartment_description
  name           = var.compartment_name
  enable_delete  = true

  freeform_tags = local.common_tags
}