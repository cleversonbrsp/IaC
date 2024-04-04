resource "oci_identity_compartment" "lab01" {
  compartment_id = var.oci_root_tenancy
  description    = "devopslabs.site"
  name           = "k8s"
  enable_delete  = true
}