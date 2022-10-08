terraform {
  required_version = "1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.32.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

module "sample_instance" {
  source = "./modules/app"

  project      = var.project
  service_name = "sample-service"
  environment  = "dev"
}
