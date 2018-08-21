terraform {
  required_version = "~> 0.11.5"
}

# GCP Kubernetes Terraform Template For Habitat Demo
#
# https://www.terraform.io/docs/providers/google/r/container_cluster.html

# Configure variables

variable "gcp_project_id" {}
variable "gcp_kube_cluster_name" {}
variable "gcp_kube_cluster_zone" {}
variable "gcp_kube_cluster_zone_extra1" {}
variable "gcp_kube_cluster_zone_extra2" {}
variable "gcp_kube_cluster_master_user" {}
variable "gcp_kube_cluster_master_pass" {}
variable "hab_container_service_account_name" {}
variable "create_habitat_service_account" {}

# Create a service account for habitat to publish images to the container registry with

# service accounts require a unique name so constrain this via a flag for convenience
resource "google_service_account" "habitat_container_service_account" {
  count = "${var.create_habitat_service_account}"
  project = "${var.gcp_project_id}"
  account_id   = "${var.hab_container_service_account_name}"
  display_name = "${var.hab_container_service_account_name}"
}

# grant this account sufficient privileges for container CRUD
resource "google_project_iam_member" "project_storage_admin" {
  count = "${var.create_habitat_service_account}"
  project = "${var.gcp_project_id}"
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.habitat_container_service_account.email}"
}

# Create the cluster

resource "google_container_cluster" "primary" {
  project = "${var.gcp_project_id}"
  name               = "${var.gcp_kube_cluster_name}"
  zone               = "${var.gcp_kube_cluster_zone}"
  initial_node_count = 1

  additional_zones = [
    "${var.gcp_kube_cluster_zone_extra1}",
    "${var.gcp_kube_cluster_zone_extra2}",
  ]

  master_auth {
    username = "${var.gcp_kube_cluster_master_user}"
    password = "${var.gcp_kube_cluster_master_pass}"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

# The following outputs allow authentication and connectivity to the GKE Cluster

output "client_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.primary.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
}
