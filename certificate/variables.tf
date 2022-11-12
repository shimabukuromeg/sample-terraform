
variable "project_id" {
  type        = string
  description = "プロジェクトID"
}

variable "name_prefix" {
  type        = string
  default     = "default"
  description = "リソースに付ける名前のプレフィックス"
}

variable "domain" {
  type = object({
    project_id : string
    managed_zone : string
    record_name : string
    zone_suffix : string
  })
  description = "割り当てるドメインの情報"
}
