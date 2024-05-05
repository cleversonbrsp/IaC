resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = "kualydahdie"
  friendly_name               = "altah-kualydahdie"
  description                 = "Labzin de teste"
  location                    = "US"
  delete_contents_on_destroy  = true
  
}

#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset#example-usage---bigquery-dataset-basic