# ========================================
# Outputs
# ========================================

output "bucket_id" {
  description = "The OCID of the bucket"
  value       = oci_objectstorage_bucket.this.id
}

output "bucket_name" {
  description = "The name of the bucket"
  value       = oci_objectstorage_bucket.this.name
}

output "bucket_namespace" {
  description = "The namespace of the bucket"
  value       = oci_objectstorage_bucket.this.namespace
}

output "bucket_etag" {
  description = "The entity tag (ETag) for the bucket"
  value       = oci_objectstorage_bucket.this.etag
}

output "bucket_created_by" {
  description = "The OCID of the user who created the bucket"
  value       = oci_objectstorage_bucket.this.created_by
}

output "bucket_time_created" {
  description = "The date and time the bucket was created"
  value       = oci_objectstorage_bucket.this.time_created
}

output "bucket_uri" {
  description = "The URI of the bucket"
  value       = "https://objectstorage.${var.oci_region}.oraclecloud.com/n/${oci_objectstorage_bucket.this.namespace}/b/${oci_objectstorage_bucket.this.name}/"
}

output "bucket_compartment_id" {
  description = "The OCID of the compartment containing the bucket"
  value       = oci_objectstorage_bucket.this.compartment_id
}

output "bucket_access_type" {
  description = "The type of public access enabled on this bucket"
  value       = oci_objectstorage_bucket.this.access_type
}

output "bucket_storage_tier" {
  description = "The storage tier type assigned to the bucket"
  value       = oci_objectstorage_bucket.this.storage_tier
}

output "bucket_versioning" {
  description = "The versioning status on the bucket"
  value       = oci_objectstorage_bucket.this.versioning
}

