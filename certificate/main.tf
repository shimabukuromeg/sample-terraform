# 証明書を発行します
locals {
  fqdn          = var.domain.record_name != "" ? "${var.domain.record_name}.${var.domain.zone_suffix}" : var.domain.zone_suffix
  wildcard_fqdn = "*.${local.fqdn}"
}

data "google_dns_managed_zone" "default" {
  project = var.domain.project_id
  name    = var.domain.managed_zone
}

# DNS
# Enable Certificate Manager API
resource "google_project_service" "certificate-manager" {
  project = var.project_id
  service = "certificatemanager.googleapis.com"
}

##############################################################
###   DNS 認証を作成する
###   $ gcloud certificate-manager dns-authorizations list
##############################################################

# ドメイン認証: 要求
# ACMEプロトコルの設定が出てきます。
resource "google_certificate_manager_dns_authorization" "default" {
  project     = var.project_id
  name        = "${var.name_prefix}-example"
  description = "default dns"
  domain      = local.fqdn

  depends_on = [
    google_project_service.certificate-manager
  ]
}

# ドメイン認証: 設定
locals {
  auth_record = google_certificate_manager_dns_authorization.default.dns_resource_record.0
}

##########################################
###   DNS に CNAME レコードを追加します。
##########################################
resource "google_dns_record_set" "dns" {
  project      = var.domain.project_id
  name         = local.auth_record.name
  type         = local.auth_record.type
  ttl          = 600
  managed_zone = data.google_dns_managed_zone.default.name
  rrdatas      = [local.auth_record.data]
}

output "dns_record" {
  value = local.auth_record
}

#######################################################
### DNS 認証を参照する Googleマネージド証明書を作成します
#######################################################
resource "google_certificate_manager_certificate" "default" {
  project     = var.project_id
  name        = "${var.name_prefix}-example"
  description = "The default cert"
  scope       = "DEFAULT"

  managed {
    domains = [
      local.fqdn,
      local.wildcard_fqdn,
    ]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.default.id,
    ]
  }
}

##########################################
###  証明書をロードバランサーにデプロイします
##########################################

# 証明書 mapの作成（ドメイン -> 証明書の紐づけセット）
resource "google_certificate_manager_certificate_map" "default" {
  project     = var.project_id
  name        = "${var.name_prefix}-example"
  description = "certificate map"

  depends_on = [
    google_certificate_manager_certificate.default
  ]
}

# 証明書マップエントリを作成して、証明書と証明書マップに関連付けます（ドメイン -> 証明書の紐づけ）
resource "google_certificate_manager_certificate_map_entry" "default" {
  project      = var.project_id
  name         = "${var.name_prefix}-example"
  description  = "certificate map entry"
  map          = google_certificate_manager_certificate_map.default.name
  certificates = [google_certificate_manager_certificate.default.id]
  matcher      = "PRIMARY"

  lifecycle {
    replace_triggered_by = [
      google_certificate_manager_certificate.default
    ]
  }
}

output "certificate" {
  value       = google_certificate_manager_certificate_map.default
  description = "証明書とドメインのマッピング情報"
}
