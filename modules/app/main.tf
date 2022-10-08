# 仮想マシンインスタンス（google_compute_instance）を作成するモジュール
# 属性にvariable、 variableを利用して組み立てたlocals、インターポレーションでvariableを埋め込んだ文字列を利用

terraform {
  required_version = "1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.32.0"
    }
  }
}

# localsは、リソース内で利用する入出力に関与しない変数
locals {
  common_labels = {
    service     = var.service_name
    environment = var.environment
  }
}

resource "google_compute_instance" "default" {
  project = var.project
  zone    = var.zone

  name = "${var.service_name}-vm"

  machine_type = var.machine_type

  labels = local.common_labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }
}
