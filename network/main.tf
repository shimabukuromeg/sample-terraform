###########################################
## 変数
###########################################
variable "project_id" {
  type        = string
  description = "GCPプロジェクトID"
}

variable "region" {
  type        = string
  description = "GCPリージョン"
}

###########################################
## メイン
###########################################
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

###########################################
## アウトプット
###########################################
output "vpc-access-connector-link" {
  description = "CloudRun等で使用するVPCサブネット(VPC Connector専用)のselflink"
  value = {
    self_link = google_compute_subnetwork.peering-network-subnet.self_link,
    name      = google_compute_subnetwork.peering-network-subnet.name
  }
}

output "network" {
  description = "CloudRun等で使用するVPC"
  value = {
    id   = google_compute_network.peering_network.id
    name = google_compute_network.peering_network.name
  }
}
