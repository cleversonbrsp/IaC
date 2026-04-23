data "oci_objectstorage_namespace" "ns" {}

resource "oci_objectstorage_bucket" "files" {
  compartment_id = local.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "files"

  access_type  = "NoPublicAccess"
  storage_tier = "Standard"

  versioning = "Disabled"

  defined_tags = var.common_tags.defined_tags

  depends_on = [time_sleep.after_compartment]
}

