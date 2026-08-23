# -----------------------------------------------------------------------------
# Secret Manager - Phase 3, Task 6
# -----------------------------------------------------------------------------
# Demonstrates: secrets stored centrally, retrieved dynamically by both
# Jenkins (CI/CD) and Kubernetes pods - never hardcoded in YAML or the Jenkinsfile.

resource "google_secret_manager_secret" "app_secret_key" {
  secret_id = "${var.environment}-app-secret-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "app_secret_key_v1" {
  secret      = google_secret_manager_secret.app_secret_key.id
  secret_data = "replace-with-a-real-generated-secret-value"
  # In practice: generate with `openssl rand -base64 32` and pass via
  # -var, never hardcode a real secret value in .tf source.
}

# Example: a "database password" secret, standing in for whatever
# credential your app would need in a fuller build
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.environment}-db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password_v1" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = "replace-with-a-real-generated-password"
}

# Grant the GKE node SA read access via Workload Identity, so pods can
# pull secrets using the Secret Manager CSI driver without embedding
# any credential in the pod spec
resource "google_secret_manager_secret_iam_member" "app_secret_key_access" {
  secret_id = google_secret_manager_secret.app_secret_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_secret_manager_secret_iam_member" "db_password_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke_nodes.email}"
}
