resource "oci_identity_compartment" "dayz_compartment" {
  compartment_id = var.comp_id
  description    = "dayz-server compartment"
  name           = "dayz-server"
  enable_delete  = true
}