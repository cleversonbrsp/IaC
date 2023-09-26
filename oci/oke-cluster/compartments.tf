resource "oci_identity_compartment" "oke_comp" {
  compartment_id = var.oci_root_compartment
  description    = "OKE Homolog - terraform environment."
  name           = "OKE_HML"
  enable_delete  = true
}