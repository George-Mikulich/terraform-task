terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.74.0"
    }
  }

  backend "gcs" {
    bucket = "cde668cb35a65d2c-bucket-tfstate"
    prefix = "terraform/state"
  }

  required_version = ">= 0.14"
}

provider "google" {
  project = var.gcp_project_settings.project_id
  region  = var.gcp_project_settings.region
}

provider "kubernetes" {
 host                   = "http://${module.private-gke-cluster.bastion_endpoint}:443"
 client_key             = base64decode(module.private-gke-cluster.key)
 cluster_ca_certificate = base64decode(module.private-gke-cluster.ca_cert)
}