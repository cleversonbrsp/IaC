# ========================================
# Object Storage Bucket
# ========================================

locals {
  # Use provided namespace or fetch from data source
  bucket_namespace = coalesce(var.bucket_namespace, data.oci_objectstorage_namespace.bucket_namespace.namespace)
  
  # Merge bucket configuration with defaults
  bucket_config = merge(
    {
      access_type           = "NoPublicAccess"
      auto_tiering          = null
      storage_tier          = "Standard"
      versioning            = "Disabled"
      object_events_enabled = false
      metadata              = {}
      kms_key_id           = null
    },
    var.bucket_config
  )
}

resource "oci_objectstorage_bucket" "this" {
  # Required
  compartment_id = var.compartment_id
  name           = var.bucket_name
  namespace      = local.bucket_namespace

  # Optional - Bucket Configuration
  access_type           = local.bucket_config.access_type
  auto_tiering          = local.bucket_config.auto_tiering
  storage_tier          = local.bucket_config.storage_tier
  versioning            = local.bucket_config.versioning
  object_events_enabled = local.bucket_config.object_events_enabled
  metadata              = local.bucket_config.metadata
  kms_key_id            = local.bucket_config.kms_key_id

  # Tags
  #defined_tags  = var.defined_tags
  #freeform_tags = var.freeform_tags

  # Retention Rules
  dynamic "retention_rules" {
    for_each = var.retention_rules
    content {
      display_name = retention_rules.value.display_name
      duration {
        time_amount = retention_rules.value.time_amount
        time_unit   = upper(retention_rules.value.time_unit)
      }
      time_rule_locked = retention_rules.value.time_rule_locked
    }
  }
}