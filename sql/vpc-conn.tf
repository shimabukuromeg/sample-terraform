resource "google_project_service" "vpcaccess" {
  project = var.project_id
  service = "vpcaccess.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }
}

resource "google_vpc_access_connector" "vpcaccess" {
  provider     = google-beta
  region       = var.region
  project      = var.project_id
  name         = "vpc-con-middleware"
  machine_type = "e2-micro"
  subnet {
    name = var.vpc-subnet-name
  }
  depends_on = [
    google_project_service.vpcaccess
  ]
}
