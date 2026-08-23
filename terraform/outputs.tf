output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.primary.endpoint
  sensitive = true
}

output "get_credentials_command" {
  description = "Run this after apply to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "jenkins_service_account_email" {
  value = google_service_account.jenkins.email
}

output "gke_node_service_account_email" {
  value = google_service_account.gke_nodes.email
}
