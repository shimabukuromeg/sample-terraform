# self_link はリソースのURL
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#self_link

output "self_link" {
  description = "A self link of an instance"
  value       = google_compute_instance.default.self_link
}
