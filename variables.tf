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
  default     = "10.1.0.10"
  description = "IP address of Compute Engine to connect to private GKE cluster"
}

variable "cluster_bastion_startup" {
  default     = <<EOT
apt-get install kubectl -y &&
apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y &&
export HOME=/home/guga &&
su guga -c "gcloud container clusters get-credentials gke-cluster --zone us-west1-c --project my-beautiful-cluster2" &&
kubectl proxy --port 443 --address 10.1.0.10 --accept-hosts "^*\.*\.*\.*$" &
EOT
  description = "self-descriptive)"
}