provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

locals {
  cluster_name = "${var.cluster_name}-${var.env_name}"
}

# GKE Cluster Resources
# GKE Cluster with default node pool
# IAM Binding to allow Kubernetes Engine Service Agent to manage GCP resources

resource "google_container_cluster" "ms-cluster" {
  name     = local.cluster_name
  location = var.gcp_region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  ip_allocation_policy {}
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${local.cluster_name}-node-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.ms-cluster.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    service_account = var.node_service_account
  }
}

resource "google_project_iam_member" "gke_service_agent" {
  project = var.gcp_project
  role    = "roles/container.clusterAdmin"
  member  = "serviceAccount:${var.gke_service_account_email}"
}

resource "google_compute_firewall" "ms_cluster_ingress" {
  name    = "${local.cluster_name}-ingress"
  network = var.vpc_name

  description = "Inbound traffic from within the same network"
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ms-up-running"]
}

resource "google_compute_firewall" "ms_cluster_egress" {
  name    = "${local.cluster_name}-egress"
  network = var.vpc_name

  description = "Outbound traffic to anywhere"
  direction   = "EGRESS"
  priority    = 1000

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["ms-up-running"]
}

resource "google_container_cluster" "ms_up_running" {
  name     = local.cluster_name
  location = var.gcp_region

  network    = var.vpc_name
  subnetwork = var.cluster_subnet_name

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {}

  # Enable required addons, optional
  addons_config {
    http_load_balancing {
      disabled = false
    }
  }

  # Optional, if you want private nodes
  # private_cluster_config {
  #   enable_private_nodes    = true
  #   enable_private_endpoint = false
  #   master_ipv4_cidr_block  = "172.16.0.0/28"
  # }

  # Optional: tags for firewall rule targeting
  resource_labels = {
    name = "ms-up-running"
  }

  depends_on = [
    google_project_iam_member.gke_service_agent
  ]
}

resource "google_service_account" "ms_node" {
  account_id   = "${replace(local.cluster_name, ".", "-")}-node"
  display_name = "${local.cluster_name} Node Pool SA"
}

# Attach IAM roles to the node pool service account
resource "google_project_iam_member" "ms_node_container_node_service" {
  project = var.gcp_project
  role    = "roles/container.nodeServiceAccount"
  member  = "serviceAccount:${google_service_account.ms_node.email}"
}

resource "google_project_iam_member" "ms_node_logging_viewer" {
  project = var.gcp_project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.ms_node.email}"
}

resource "google_project_iam_member" "ms_node_monitoring_viewer" {
  project = var.gcp_project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.ms_node.email}"
}

# Optional: access to Container Registry / Artifact Registry
resource "google_project_iam_member" "ms_node_artifact_registry_reader" {
  project = var.gcp_project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.ms_node.email}"
}

resource "google_container_node_pool" "ms_node_group" {
  name     = "microservices"
  cluster  = google_container_cluster.ms_up_running.name
  location = var.gcp_region

  node_locations = var.node_zones # Optional, for regional clusters

  node_config {
    machine_type = var.nodegroup_instance_types[0]
    disk_size_gb = var.nodegroup_disk_size

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    service_account = google_service_account.ms_node.email
    tags            = ["ms-up-running"]
  }

  initial_node_count = var.nodegroup_desired_size

  autoscaling {
    min_node_count = var.nodegroup_min_size
    max_node_count = var.nodegroup_max_size
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  depends_on = [
    google_project_iam_member.ms_node_container_node_service,
    google_project_iam_member.ms_node_logging_viewer,
    google_project_iam_member.ms_node_monitoring_viewer,
    google_project_iam_member.ms_node_artifact_registry_reader
  ]
}

resource "local_file" "kubeconfig" {
  content = <<KUBECONFIG
apiVersion: v1
kind: Config
preferences: {}
current-context: ${google_container_cluster.ms_up_running.name}
clusters:
- name: ${google_container_cluster.ms_up_running.name}
  cluster:
    certificate-authority-data: ${google_container_cluster.ms_up_running.master_auth.0.cluster_ca_certificate}
    server: https://${google_container_cluster.ms_up_running.endpoint}
contexts:
- name: ${google_container_cluster.ms_up_running.name}
  context:
    cluster: ${google_container_cluster.ms_up_running.name}
    user: ${google_container_cluster.ms_up_running.name}-user
users:
- name: ${google_container_cluster.ms_up_running.name}-user
  user:
    auth-provider:
      name: gcp
KUBECONFIG

  filename = "kubeconfig"
}

