variable "zone" {
  default     = "us-west1-c"
  description = "gcp zone"
}

variable "region" {
  default     = "us-west1"
  description = "gcp region"
}

variable "project_id" {
  default     = "my-beautiful-cluster2"
  description = "project ID"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

variable "gke_bastion_ip" {
  default = "10.1.0.10"
  description = "IP address of Compute Engine to connect to private GKE cluster"
}