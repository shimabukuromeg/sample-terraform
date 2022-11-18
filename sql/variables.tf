variable "name_prefix" {
  type        = string
  default     = "default"
  description = "リソースに付ける名前のプレフィックス"
}

variable "project_id" {
  type        = string
  description = "GCPプロジェクトID"
}

variable "db-version" {
  default     = "POSTGRES_13"
  description = "Cloud SQL for PostgreSQLのバージョン"
}

variable "db-tier" {
  type        = string
  description = "Cloud SQL for PostgreSQLのインスタンスタイプ, カスタムマシンタイプの場合は`db-custom-{CPUs}-{Memory_in_MB}`で指定"
}

variable "db-databases" {
  type        = list(string)
  default     = []
  description = "作成するデータベース名"
}

variable "db-network-id" {
  type        = string
  description = "Cloud SQL for PostgreSQLのインスタンスに許可する`google_compute_network.id`"
}

variable "region" {
  type        = string
  description = "GCPリージョン"
}

variable "vpc-subnet-name" {
  type        = string
  description = "Redisに接続するためのVPCコネクターを作るredis-network-idのサブネットのname"
}
