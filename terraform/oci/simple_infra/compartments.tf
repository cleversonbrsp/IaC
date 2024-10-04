resource "oci_identity_compartment" "simple_infra" {
  compartment_id = var.oci_root_compartment
  description    = "simple infra whit a network and instances"
  name           = "simple infra"
  enable_delete  = true
}