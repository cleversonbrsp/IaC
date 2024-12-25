resource "oci_identity_compartment" "basic-cluster" {
  compartment_id = var.oci_root_tenancy
  description    = "OKE Basic Cluster"
  name           = "k8s"
  enable_delete  = true
}