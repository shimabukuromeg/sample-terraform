variable "pool_id" {
  type = string
}

variable "repository" {
  type = string
}

variable "sa_id" {
  type = string
}

resource "google_service_account_iam_member" "binding" {
  service_account_id = var.sa_id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${var.pool_id}/attribute.repository/${var.repository}"
}
