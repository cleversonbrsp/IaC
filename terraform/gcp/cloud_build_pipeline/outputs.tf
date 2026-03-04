output "repository_name" {
  description = "Name of the Cloud Source Repository"
  value       = google_sourcerepo_repository.repo.name
}

output "repository_url" {
  description = "Clone URL for the Cloud Source Repository"
  value       = google_sourcerepo_repository.repo.url
}

output "trigger_id" {
  description = "ID of the Cloud Build trigger"
  value       = google_cloudbuild_trigger.trigger.trigger_id
}

output "trigger_name" {
  description = "Name of the Cloud Build trigger"
  value       = google_cloudbuild_trigger.trigger.name
}

output "app_engine_app_id" {
  description = "Application ID of the App Engine app"
  value       = google_app_engine_application.app.app_id
}

output "clone_commands" {
  description = "Commands to clone the repo and deploy (after pushing app files)"
  value       = <<-EOT
    # Clone and add your app files (main.py, app.yaml, cloudbuild.yaml), then:
    gcloud source repos clone ${var.repository_name}
    cd ${var.repository_name}
    # Copy main.py, app.yaml, cloudbuild.yaml from this folder's sample_app/
    git add .
    git commit -m "Updating"
    git push
    # Trigger will run automatically. To open the app:
    gcloud app browse
  EOT
}
