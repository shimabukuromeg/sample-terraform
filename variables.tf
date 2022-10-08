variable "project" {
  description = "A name of a GCP project"
  type        = string
  default     = null
}

variable "region" {
  description = "A region used in a compute instance"
  type        = string
  default     = "asia-northeast1"
  validation {
    condition     = var.region == "asia-northeast1"
    error_message = "The region must be in asia-northeast1 region."
  }
}

variable "zone" {
  description = "A zone used in a compute instance"
  type        = string
  default     = "asia-northeast1-c"

  validation {
    condition     = contains(["asia-northeast1-a", "asia-northeast1-b", "asia-northeast1-c"], var.zone)
    error_message = "The zone must be in asia-northeast1 region."
  }
}
