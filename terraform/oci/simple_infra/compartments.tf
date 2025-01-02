resource "oci_identity_compartment" "simpleinfra" {
  compartment_id = var.comp_id
  description    = "simple infra whit a network and instance"
  name           = "lab-01"
  enable_delete  = true
}