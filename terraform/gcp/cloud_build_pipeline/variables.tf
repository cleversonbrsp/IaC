variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for App Engine and resources"
  type        = string
  default     = "us-central1"
}

variable "repository_name" {
  description = "Name of the Cloud Source Repository (lab validation expects 'cleverson')"
  type        = string
  default     = "cleverson"
}

variable "trigger_name" {
  description = "Name of the Cloud Build trigger (lab validation expects 'Whizlabs')"
  type        = string
  default     = "Whizlabs"
}

variable "branch_regex" {
  description = "Branch pattern for the trigger - use .* for any branch"
  type        = string
  default     = ".*"
}

variable "cloud_build_config_file" {
  description = "Path to Cloud Build config file in the repository"
  type        = string
  default     = "cloudbuild.yaml"
}

variable "app_engine_location_id" {
  description = "Location ID for App Engine application (e.g. us-central, europe-west)"
  type        = string
  default     = "us-central"
}

