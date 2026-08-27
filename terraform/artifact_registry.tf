# -----------------------------------------------------------------------------
# Artifact Registry - GCP's equivalent of Amazon ECR
# -----------------------------------------------------------------------------
# Created here in Phase 3 even though it's used in Phase 4, since it's
# infrastructure and belongs in Terraform, not created ad-hoc via gcloud.

resource "google_artifact_registry_repository" "app_repo" {
  location      = var.region
  repository_id = "${var.environment}-repo"
  description   = "Docker images for the Task Management API"
  format        = "DOCKER"

  # Vulnerability scanning (Phase 6, Task 13) is on by default for
  # Artifact Registry in most projects - no extra resource needed here.
}

output "artifact_registry_url" {
  description = "Push/pull URL prefix for this repo, e.g. used in docker build -t"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app_repo.repository_id}"
}
