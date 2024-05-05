provider "google" {
  credentials = "${file("account.json")}"
  project     = "projeto-zomboid"
  region      = "us-west4"
}