# ------------------------------------------------------------------------------
# Enable required APIs (Whizlabs lab: Cloud Build, Source Repo, App Engine)
# ------------------------------------------------------------------------------

resource "google_project_service" "cloudbuild" {
  project            = var.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sourcerepo" {
  project            = var.project_id
  service            = "sourcerepo.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "appengine" {
  project            = var.project_id
  service            = "appengine.googleapis.com"
  disable_on_destroy = false
}

# ------------------------------------------------------------------------------
# Cloud Source Repository (lab: create repo "cleverson")
# ------------------------------------------------------------------------------

resource "google_sourcerepo_repository" "repo" {
  name    = var.repository_name
  project = var.project_id

  depends_on = [google_project_service.sourcerepo]
}

# ------------------------------------------------------------------------------
# App Engine application (required for gcloud app deploy in the pipeline)
# ------------------------------------------------------------------------------

resource "google_app_engine_application" "app" {
  project       = var.project_id
  location_id   = var.app_engine_location_id
  database_type = "CLOUD_FIRESTORE"

  depends_on = [google_project_service.appengine]
}

# ------------------------------------------------------------------------------
# Cloud Build trigger (lab: name "Whizlabs", push to branch, cloudbuild.yaml)
# ------------------------------------------------------------------------------

resource "google_cloudbuild_trigger" "trigger" {
  name    = var.trigger_name
  project = var.project_id

  trigger_template {
    repo_name   = var.repository_name
    branch_name = var.branch_regex
  }

  filename = var.cloud_build_config_file

  depends_on = [
    google_project_service.cloudbuild,
    google_sourcerepo_repository.repo,
  ]
}
