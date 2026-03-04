# -----------------------------------------------------------------------------
# OCI Object Storage bucket (apprest-archive - pipeline archive/restore)
# -----------------------------------------------------------------------------

resource "oci_objectstorage_bucket" "billing_archive" {
  compartment_id = local.compartment_id
  name           = var.bucket_name
  namespace      = var.bucket_namespace

  access_type  = "NoPublicAccess"
  storage_tier = "Standard"
  versioning   = "Disabled"
}
