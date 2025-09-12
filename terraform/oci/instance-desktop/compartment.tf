resource "oci_identity_compartment" "crodrigues" {
  compartment_id = var.comp_id
  description    = "Desktop Instances"
  name           = "desktop-instances"
  enable_delete  = true
}