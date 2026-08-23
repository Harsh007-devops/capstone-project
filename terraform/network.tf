# -----------------------------------------------------------------------------
# VPC with public and private subnets
# -----------------------------------------------------------------------------
# GCP's model differs from AWS: "public/private" here is expressed via
# --no-enable-private-ip-google-access on a public-facing subnet, and
# --enable-private-ip-google-access + Cloud NAT (no external IPs) on the
# private one. GKE nodes live in the private subnet; only the NAT gateway
# and any load balancers get public IPs.

resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
}

# --- "Public" subnet: for anything that needs a direct external IP
# (e.g. the Jenkins/workstation VM's network, bastion-style access) ---
resource "google_compute_subnetwork" "public" {
  name          = "${var.environment}-public-subnet"
  ip_cidr_range = "10.10.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = false
}

# --- "Private" subnet: GKE nodes and pods live here, no external IPs ---
resource "google_compute_subnetwork" "private" {
  name          = "${var.environment}-private-subnet"
  ip_cidr_range = "10.20.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true

  # Secondary ranges required for GKE VPC-native (alias IP) networking
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.30.0.0/16"
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.40.0.0/20"
  }
}

# --- Cloud Router + Cloud NAT: lets the private subnet reach the internet
# (pull images, hit APIs) without any node having a public IP ---
resource "google_compute_router" "router" {
  name    = "${var.environment}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.environment}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# --- Firewall rules ---

# Allow internal traffic between resources in the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.10.0.0/20", "10.20.0.0/20", "10.30.0.0/16", "10.40.0.0/20"]
}

# Allow SSH via GCP's Identity-Aware Proxy range only (not the whole internet)
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.environment}-allow-iap-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # This is GCP's fixed IAP forwarding range, not a real-world CIDR you need to guess
  source_ranges = ["35.235.240.0/20"]
}

# Allow Jenkins UI (port 8080) - tightened to your IP is recommended,
# 0.0.0.0/0 kept here to match the quick-start docs from Day 0
resource "google_compute_firewall" "allow_jenkins" {
  name    = "${var.environment}-allow-jenkins"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jenkins"]
}
