resource "oci_identity_compartment" "simpleinfra" {
  compartment_id = var.oci_root_tenancy
  description    = "simple infra whit a network and instances"
  name           = "lab-simpleinfra-01"
  enable_delete  = true
}