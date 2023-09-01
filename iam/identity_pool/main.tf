variable "project_id" {
  type = string
}

variable "pool_id" {
  type = string
}

variable "provider_id" {
  default = "github"
}

resource "google_iam_workload_identity_pool" "pool" {
  provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
}

output "workload_identity_provider" {
  value = {
    id   = google_iam_workload_identity_pool.pool.id,
    name = google_iam_workload_identity_pool.pool.name,
  }
}

output "workload_identity_provider_github" {
  value = {
    id   = google_iam_workload_identity_pool_provider.github.id,
    name = google_iam_workload_identity_pool_provider.github.name,
  }
}

resource "google_iam_workload_identity_pool_provider" "github" {
  provider                           = google-beta
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
