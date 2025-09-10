resource "oci_identity_compartment" "crodrigues" {
  compartment_id = var.comp_id
  description    = "Cleverson's Compartment"
  name           = "crodrigues"
  enable_delete  = true
}