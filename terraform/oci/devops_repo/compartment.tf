resource "oci_identity_compartment" "devops_repo" {
  compartment_id = var.oci_root_tenancy
  description    = "devops_repo"
  name           = "devops_repo"
  enable_delete  = true
}