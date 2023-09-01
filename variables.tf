# variable "project" {
#   description = "A name of a GCP project"
#   type        = string
#   default     = null
# }

# variable "region" {
#   description = "A region used in a compute instance"
#   type        = string
#   default     = "asia-northeast1"
#   validation {
#     condition     = var.region == "asia-northeast1"
#     error_message = "The region must be in asia-northeast1 region."
#   }
# }

# variable "zone" {
#   description = "A zone used in a compute instance"
#   type        = string
#   default     = "asia-northeast1-c"

#   validation {
#     condition     = contains(["asia-northeast1-a", "asia-northeast1-b", "asia-northeast1-c"], var.zone)
#     error_message = "The zone must be in asia-northeast1 region."
#   }
# }

# Variables

variable "project_id" {
  description = "the project to deploy the resources"
  type        = string
}

variable "name" {
  description = "the name prefix for load balancer resources"
  type        = string
}

variable "region" {
  description = "The region of the backend."
  type        = string
}

variable "cloud_run_service" {
  description = "The name of the Cloud Run service."
  type        = string
}

variable "domain" {
  description = "The domain name of the load balancer."
  type        = string
}
