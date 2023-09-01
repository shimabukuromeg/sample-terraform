##############################################################
###  ネットワーク
##############################################################
# VPC作成
resource "google_compute_network" "peering_network" {
  name                    = "private-network"
  auto_create_subnetworks = "false"
}

# VPCコネクタ専用
resource "google_compute_subnetwork" "peering-network-subnet" {
  project       = var.project_id
  name          = "peering-network-subnet"
  description   = "peering-network-subnet"
  ip_cidr_range = "10.8.0.0/28" // デフォルトサブネットの外で/28確保
  region        = var.region
  network       = google_compute_network.peering_network.id
}

# プライベートIPでアクセスするための設定（APIの有効化）
resource "google_project_service" "network" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
}

# Private IP
resource "google_compute_global_address" "vpc_private_ip" {
  # NOTE: 一応問題なかったけど、172.17.0.0/16はGCPのデフォルトのVPCの範囲で、使用不可だが、割り当てられる可能性があるので回避したいところ
  name          = "${var.name_prefix}-db-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.peering_network.id
}


# Private IP -> VPC
resource "google_service_networking_connection" "vpc_conn" {
  network                 = google_compute_network.peering_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.vpc_private_ip.name]
  depends_on = [
    google_project_service.network
  ]
}


######################################################
#### Cloud SQL for PostgreSQL
######################################################
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "default" {
  project             = var.project_id
  name                = "${var.name_prefix}-db-${random_id.db_name_suffix.hex}"
  database_version    = var.db-version
  region              = var.region
  deletion_protection = false # 検証で作成するため、あとで消したい

  settings {
    tier = var.db-tier

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.peering_network.id
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }

  depends_on = [
    google_service_networking_connection.vpc_conn
  ]
}

######################################################
#### サーバーレス VPC コネクタ
######################################################

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
    name = google_compute_subnetwork.peering-network-subnet.name
  }
  depends_on = [
    google_project_service.vpcaccess
  ]
}


######################################################
### IAMユーザー, サービスアカウント
######################################################
locals {
  management_users = [
    "migration",
    "admin",
  ]
}

resource "google_sql_user" "managers" {
  for_each = toset(local.management_users)
  name     = each.key
  instance = google_sql_database_instance.default.name
  password = random_password.managers_db_password[each.key].result
}

resource "random_password" "managers_db_password" {
  for_each         = toset(local.management_users)
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "google_sql_database" "database" {
  for_each = toset(var.db-databases)
  name     = each.key
  instance = google_sql_database_instance.default.name
}
