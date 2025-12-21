		terraform {
		  backend "oci" {
		    bucket = "terraform-bucket"
		    namespace = "gr5ugxwrsywe"
		    key = "nvt-infra/terraform.tfstate"
		    region = "sa-saopaulo-1"
		  }
		}