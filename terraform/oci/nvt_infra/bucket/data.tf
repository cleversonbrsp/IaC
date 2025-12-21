# ========================================
# Data Sources
# ========================================

# Automatically fetch object storage namespace if not provided
data "oci_objectstorage_namespace" "bucket_namespace" {
  compartment_id = var.compartment_id
}

