# Google provider settings
provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}"
  zone               = "${var.zone}"
  initial_node_count = "${var.initial_node_count}"
  enable_legacy_abac = false
  min_master_version = "${var.gke_min_version}"
  node_version       = "${var.gke_min_version}"
  subnetwork         = "default"

  node_config {
    disk_size_gb = "${var.node_disk_size}"
    machine_type = "${var.node_machine_type}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  addons_config {
    kubernetes_dashboard {
      disabled = false
    }
  }
}

# firewall rule SSH
resource "google_compute_firewall" "firewall_kubernetes" {
  name    = "gke-inbound-allow"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  description   = "allow inbound for kubernetes"
  source_ranges = ["0.0.0.0/0"]
}
