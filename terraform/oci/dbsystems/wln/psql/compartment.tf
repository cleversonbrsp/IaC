# 1 - Compartment (primeiro)
resource "oci_identity_compartment" "psql_hot_cold_lab" {
  compartment_id = var.parent_compartment_id
  name           = "psql_hot_cold_lab"
  description    = "Compartment for PostgreSQL hot/cold lab (VCN, subnet, DB system, OpenVPN)"
  enable_delete  = true
}
