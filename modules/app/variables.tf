variable "project" {
  description = "A name of a GCP project"
  type        = string
  default     = null
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

variable "service_name" {
  description = "A name of a service"
  type        = string
}

variable "environment" {
  description = "A name of an environment"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "The environment must be development, staging, or production."
  }
}

variable "machine_type" {
  description = "value of machine_type"
  type        = string
  default     = "f1-micro"
}

