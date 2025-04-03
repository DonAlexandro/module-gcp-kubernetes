output "gke_cluster_id" {
  value = google_container_cluster.ms-up-running.id
}

output "gke_cluster_name" {
  value = google_container_cluster.ms-up-running.name
}

output "gke_cluster_certificate_data" {
  value = google_container_cluster.ms-up-running.master_auth[0].cluster_ca_certificate
}

output "gke_cluster_endpoint" {
  value = google_container_cluster.ms-up-running.endpoint
}

output "gke_cluster_nodepool_id" {
  value = google_container_node_pool.ms-node-group.id
}
