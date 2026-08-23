# -----------------------------------------------------------------------------
# IAM - least-privilege service accounts (not using Owner/Editor anywhere)
# -----------------------------------------------------------------------------

# Service account GKE nodes run as - scoped to only what nodes need
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.environment}-gke-nodes"
  display_name = "GKE Node Service Account (${var.environment})"
}

resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Service account Jenkins uses to deploy - separate from the node SA,
# scoped to exactly: push images, deploy to GKE, read secrets
resource "google_service_account" "jenkins" {
  account_id   = "${var.environment}-jenkins"
  display_name = "Jenkins CI/CD Service Account (${var.environment})"
}

resource "google_project_iam_member" "jenkins_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer" # can deploy workloads, not manage cluster infra
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}


