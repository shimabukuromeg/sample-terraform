terraform {
  required_version = "1.3.4"
  backend "gcs" {
    bucket = "terraform-example-v1"
    prefix = "tfstate/v1"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.32.0"
    }
  }
}
