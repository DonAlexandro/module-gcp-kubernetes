variable "gcp_project" {
  description = "The GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region where resources will be created"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster"
  type        = string
}

variable "env_name" {
  description = "The environment name (e.g., dev, prod)"
  type        = string
}

variable "network" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnetwork" {
  description = "The name of the subnetwork"
  type        = string
}

variable "node_count" {
  description = "The number of nodes in the primary node pool"
  type        = number
}

variable "machine_type" {
  description = "The machine type for the nodes in the primary node pool"
  type        = string
}

variable "node_service_account" {
  description = "The service account for the nodes in the primary node pool"
  type        = string
}

variable "gke_service_account_email" {
  description = "The email of the GKE service account"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "cluster_subnet_name" {
  description = "The name of the subnet for the cluster"
  type        = string
}

variable "node_zones" {
  description = "The zones where the nodes will be created (for regional clusters)"
  type        = list(string)
}

variable "nodegroup_instance_types" {
  description = "The instance types for the node group"
  type        = list(string)
}

variable "nodegroup_disk_size" {
  description = "The disk size for the nodes in the node group"
  type        = number
}

variable "nodegroup_desired_size" {
  description = "The desired size of the node group"
  type        = number
  default     = 1
}

variable "nodegroup_min_size" {
  description = "The minimum size of the node group"
  type        = number
  default     = 1
}

variable "nodegroup_max_size" {
  description = "The maximum size of the node group"
  type        = number
  default     = 5
}
