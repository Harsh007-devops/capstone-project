#!/bin/bash
# Startup script for the capstone workstation VM.
# Runs automatically on first boot. Installs: gcloud components, Terraform,
# kubectl, Helm, Docker, git, Java + Jenkins.
# Logs go to /var/log/syslog - check with: sudo journalctl -u google-startup-scripts.service

set -e
exec > >(tee /var/log/startup-script.log) 2>&1
echo "=== Starting workstation setup: $(date) ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl gnupg lsb-release apt-transport-https ca-certificates software-properties-common git unzip

# ---- Docker ----
echo "=== Installing Docker ==="
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker "$(logname 2>/dev/null || echo $USER)" || true

# ---- Terraform ----
echo "=== Installing Terraform ==="
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y terraform

# ---- kubectl + gke-gcloud-auth-plugin (via gcloud components, gcloud is preinstalled on GCP VM images) ----
echo "=== Installing kubectl and GKE auth plugin ==="
gcloud components install kubectl gke-gcloud-auth-plugin --quiet || \
  apt-get install -y google-cloud-cli-gke-gcloud-auth-plugin kubectl

# ---- Helm ----
echo "=== Installing Helm ==="
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ---- Java + Jenkins ----
echo "=== Installing Java 17 + Jenkins ==="
apt-get install -y fontconfig openjdk-17-jre
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update -y
apt-get install -y jenkins
usermod -aG docker jenkins
systemctl enable jenkins
systemctl restart jenkins

echo "=== Setup complete: $(date) ==="
echo "Jenkins initial admin password will be at /var/lib/jenkins/secrets/initialAdminPassword"
echo "Versions installed:"
docker --version || true
terraform -version || true
kubectl version --client || true
helm version || true
git --version || true
