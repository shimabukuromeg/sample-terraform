provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

##############################################################
###  Cloud SQL
##############################################################z
# module "sample-sql-and-network" {
#   source = "./sample-sql-and-network"

#   project_id  = var.project_id
#   region      = var.region
#   name_prefix = "sample"

#   db-tier = "db-f1-micro"
#   db-databases = [
#     "sample_db"
#   ]
# }

##############################################################
###  Cloud Run service and permissions
##############################################################

###########################
# Cloud Run NestJS
###########################

resource "google_cloud_run_service" "api" {
  name     = "example-api"
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        # image = "asia-northeast1-docker.pkg.dev/terraform-example-363422/meg-example/nestjs:latest"
        image = "us-docker.pkg.dev/cloudrun/container/hello"

        # ports {
        #   container_port = 3005
        #   name           = "http1"
        # }
      }
    }
    # metadata {
    #   annotations = {
    #     "run.googleapis.com/vpc-access-connector" = module.sample-sql-and-network.vpcconn-connection-name
    #     "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
    #     "run.googleapis.com/cloudsql-instances"   = module.sample-sql-and-network.db-connection-name
    #   }
    # }
  }
}

resource "google_cloud_run_service_iam_member" "member-api" {
  location = google_cloud_run_service.api.location
  project  = google_cloud_run_service.api.project
  service  = google_cloud_run_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

##############################################################
###  Load Balancing resources
##############################################################

# IPアドレスを作成する
resource "google_compute_global_address" "default" {
  name = "${var.name}-address"
}

# フロントエンドの構成
resource "google_compute_global_forwarding_rule" "default" {
  name = "${var.name}-fwdrule"

  target     = google_compute_target_https_proxy.default.id
  port_range = "443"
  ip_address = google_compute_global_address.default.address
}

########################
# バックエンドの構成 NestJS
########################
resource "google_compute_backend_service" "api" {
  name = "${var.name}-api"

  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg_api.id
  }
}

# NEG
resource "google_compute_region_network_endpoint_group" "cloudrun_neg_api" {
  provider              = google-beta
  name                  = "api-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.api.name
  }
}

########################
# ホストとパスのルール
########################
resource "google_compute_url_map" "default" {
  name = "${var.name}-urlmap"

  default_service = google_compute_backend_service.api.id

  ##############
  # NestJSのルール
  ##############
  host_rule {
    hosts        = ["api.example.shimabukuromeg.dev"]
    path_matcher = "api"
  }

  path_matcher {
    name            = "api"
    default_service = google_compute_backend_service.api.id
  }

  test {
    service = google_compute_backend_service.api.id
    host    = "api.example.shimabukuromeg.dev"
    path    = "/"
  }
}


##############################################################
###  証明書作成
##############################################################
module "certificate" {
  source = "./certificate"

  project_id = var.project_id
  domain = {
    managed_zone = "shimabukuromeg-dev"
    project_id   = "gcp-github-actionsbook-368012"
    record_name  = "example"
    zone_suffix  = "shimabukuromeg.dev"
  }
}

# フロントエンドの構成 のどこか？
resource "google_compute_target_https_proxy" "default" {
  name = "${var.name}-https-proxy"

  url_map         = google_compute_url_map.default.id
  certificate_map = "//certificatemanager.googleapis.com/${module.certificate.certificate.id}"
}

################################
# HTTP-to-HTTPS resources
################################
resource "google_compute_url_map" "https_redirect" {
  name = "${var.name}-https-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "https_redirect" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.https_redirect.id
}

resource "google_compute_global_forwarding_rule" "https_redirect" {
  name = "${var.name}-fwdrule-http"

  target     = google_compute_target_http_proxy.https_redirect.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}

## workloadの設定 ##
# module "identity_pool_sample" {
#   source     = "./iam/identity_pool"
#   project_id = var.project_id
#   pool_id    = "deploy-tools"
# }

# for GitHub Actions
# GitHubから各デプロイ用SAになれるようにする
# module "github_oidc_sample" {
#   source     = "./iam/identity_pool_user"
#   pool_id    = module.identity_pool_sample.workload_identity_provider.name
#   sa_id      = google_service_account.sample-deploy.id
#   repository = "shimabukuromeg/nestjs-prisma-github-actions"
# }

resource "google_service_account" "sample-deploy" {
  account_id   = "sample-deploy"
  display_name = "GitHubActions(sample)"
  project      = var.project_id
}

##############################################################
###  権限の設定
##############################################################

###############
# デプロイ用 SA
###############

## CloudRun ##
data "google_project" "run" {
  project_id = var.project_id
}
resource "google_project_iam_member" "sample-deploy-cloudrun-roles" {
  for_each = {
    // docker push
    "roles/artifactregistry.writer" = var.project_id,
    // gcloud run deploy
    "roles/run.admin"              = data.google_project.run.project_id,
    "roles/iam.serviceAccountUser" = data.google_project.run.project_id
  }
  project = each.value
  role    = each.key
  member  = "serviceAccount:${google_service_account.sample-deploy.email}"
}

###############
# 実行用 SA
###############
resource "google_service_account" "sample-run-sa" {
  account_id   = "sample-run"
  display_name = "sample run"
  project      = data.google_project.run.project_id
}

resource "google_project_iam_member" "sample-run-cloudrun-roles" {
  for_each = toset([
    // CloudSQL
    "roles/cloudsql.client",
    // SecretManager: 実行時環境変数の読み込み(berglas経由)
    "roles/secretmanager.secretAccessor"
  ])
  project = data.google_project.run.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.sample-run-sa.email}"
}

##############################
# サービスエージェント用SA
##############################
locals {
  cloudrun-service-agent-email = "service-${data.google_project.run.number}@serverless-robot-prod.iam.gserviceaccount.com"
}

# サービスエージェントがDockerからクローンできるようにする
resource "google_project_iam_member" "sample-agent-role" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${local.cloudrun-service-agent-email}"
}

###############
# Outputs
###############
output "cloud_run_api_url" {
  value = element(google_cloud_run_service.api.status, 0).url
}

output "load_balancer_ip" {
  value = google_compute_global_address.default.address
}

# output "db_admin_user" {
#   value = module.sample-sql-and-network.db-private-ip
# }
