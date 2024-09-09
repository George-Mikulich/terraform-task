variable "cluster_name" {
  default     = "mycluster"
  description = "self-descriptive)"
}

variable "zone" {
  default     = "us-west1-c"
  description = "gcp zone"
}

variable "project" {
  default     = "my-beautiful-cluster2"
  description = "project ID"
}

variable "vpc" {
  default     = "this must throw an error if no value is specified"
  description = "VPC name"
}

variable "subnet" {
  default     = "this must throw an error if no value is specified"
  description = "subnet name"
}

variable "cidr_master" {
  default     = "10.4.4.0/28"
  description = "The IP address range for the control plane IPs."
}

variable "cidr_pods" {
  default     = "10.5.0.0/21"
  description = "The IP address range for the cluster pod IPs."
}

variable "cidr_services" {
  default     = "10.6.0.0/21"
  description = "The IP address range of the services IPs in this cluster."
}

variable "bastion_internal_ip" {
  default     = "10.1.0.10"
  description = "IP address of Compute Engine to connect to private GKE cluster"
}

variable "num_of_nodes" {
  default     = 2
  description = "it's obvious"
}

variable "machine_type" {
  default     = "e2-standard-2"
  description = "no description provided"
}

variable "disk_size_gb" {
  default     = 50
  description = "no description provided"
}

variable "cluster_bastion_startup" {
  default     = <<EOT
apt-get install kubectl -y &&
apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y &&
export HOME=/home/guga &&
su guga -c "gcloud container clusters get-credentials gke-cluster --zone us-west1-c --project my-beautiful-cluster2" &&
kubectl proxy --port 443 --address 0.0.0.0 --accept-hosts "^*\.*\.*\.*$" &
EOT
  description = "self-descriptive)"
}

variable "source_IP" {
  default     = "134.17.27.135/32"
  description = "my machine IP"
}

variable "home_IP" {
  default     = "178.125.239.2/32"
  description = "home IP"
}

variable "bsu_IP" {
  default     = "217.21.43.190/32"
  description = "BSU IP"
}