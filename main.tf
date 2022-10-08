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
