# 1 - Compartment (primeiro). Identity exige home region (ex.: GRU).
resource "oci_identity_compartment" "psql_hot_cold_lab" {
  provider       = oci.home
  compartment_id = var.parent_compartment_id
  name           = "psql_hot_cold_lab"
  description    = "Compartment for PostgreSQL hot/cold lab (VCN, subnet, DB system, OpenVPN)"
  enable_delete  = true
  defined_tags   = var.common_tags.defined_tags
}
