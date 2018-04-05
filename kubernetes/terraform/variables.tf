variable "cluster_name" {
  default     = "cluster-1"
  description = "Cluster name"
}

variable "gke_min_version" {
  default     = "1.8.8-gke.0"
  description = "GKE minimum version"
}

variable "initial_node_count" {
  default     = 2
  description = "Initial node count"
}

variable "node_disk_size" {
  default     = 20
  description = "Node disk size"
}

variable "node_machine_type" {
  default     = "g1-small"
  description = "Node machine type"
}

variable "project" {
  description = "Project ID"
}

variable "region" {
  default     = "europe-west1"
  description = "Region"
}

variable "zone" {
  default     = "europe-west1-b"
  description = "Zone"
}
