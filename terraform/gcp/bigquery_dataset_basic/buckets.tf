resource "google_storage_bucket" "crs-bucket-01" {
  name          = "crs-bucket-01"
  location      = "US"
  force_destroy = true
  project = "projeto-zomboid"

  uniform_bucket_level_access = true
}