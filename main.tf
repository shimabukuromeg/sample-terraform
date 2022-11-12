/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

# Cloud Run service and permissions

resource "google_cloud_run_service" "default" {
  name     = var.cloud_run_service
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Load Balancing resources

# IPアドレス
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

# バックエンドの構成
resource "google_compute_backend_service" "default" {
  name = "${var.name}-backend"

  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg.id
  }
}

# ホストとパスのルール
resource "google_compute_url_map" "default" {
  name = "${var.name}-urlmap"

  default_service = google_compute_backend_service.default.id
}

## 証明書
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

# マネージド証明書
# resource "google_compute_managed_ssl_certificate" "default" {
#   provider = google-beta

#   name = "${var.name}-cert"
#   managed {
#     domains = ["${var.domain}"]
#   }
# }

# フロントエンドの構成 のどこか？
resource "google_compute_target_https_proxy" "default" {
  name = "${var.name}-https-proxy"

  url_map         = google_compute_url_map.default.id
  certificate_map = "//certificatemanager.googleapis.com/${module.certificate.certificate.id}"
  # ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

# バックエンドの構成 / バックエンド サービス
resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  provider              = google-beta
  name                  = "${var.name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.default.name
  }
}

# HTTP-to-HTTPS resources

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

# Outputs

output "cloud_run_url" {
  value = element(google_cloud_run_service.default.status, 0).url
}

output "load_balancer_ip" {
  value = google_compute_global_address.default.address
}
