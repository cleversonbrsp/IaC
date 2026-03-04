# Cloud Build CI/CD Pipeline (Whizlabs Lab)

Terraform for the **Automating Deployment using CI/CD Pipeline with Google Cloud Build** lab. It provisions:

- **APIs**: Cloud Build, Cloud Source Repositories, App Engine
- **Cloud Source Repository**: `cleverson` (required for lab validation)
- **App Engine application**: So `gcloud app deploy` in the pipeline works
- **Cloud Build trigger**: `Whizlabs`, on push to any branch, using `cloudbuild.yaml`

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- GCP project and credentials (e.g. `gcloud auth application-default login` or `GOOGLE_APPLICATION_CREDENTIALS`)

## Usage

1. Copy and edit variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Set project_id (and region if needed)
   ```

2. Apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Clone the repo, add app files, and push (trigger runs automatically):
   ```bash
   gcloud source repos clone cleverson && cd cleverson
   cp ../sample_app/main.py ../sample_app/app.yaml ../sample_app/cloudbuild.yaml .
   git add . && git commit -m "Updating" && git push
   gcloud app browse
   ```

## Files

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform and provider version constraints |
| `provider.tf` | Google provider config |
| `variables.tf` | Input variable definitions |
| `main.tf` | APIs, repo, App Engine app, Cloud Build trigger |
| `outputs.tf` | Repository URL, trigger ID, clone commands |
| `terraform.tfvars` | Variable values (set `project_id`) |
| `terraform.tfvars.example` | Example variables |
| `sample_app/` | Lab app: `main.py`, `app.yaml`, `cloudbuild.yaml` |

## Lab validation

- Repository name must be **cleverson**
- Trigger name must be **Whizlabs**
- Trigger: push to branch, any branch (`.*`), config file `cloudbuild.yaml`
