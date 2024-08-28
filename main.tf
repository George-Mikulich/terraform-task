# Bucket for terraform state file.
# Commented after creating to disable message 'can't delete bucket'

# module "tfstate" {
#     source = "./tfstate-bucket"
# }

# --------------------------------------------
# VPC network and subnets --------------------
# --------------------------------------------

resource "google_compute_network" "cluster_vpc" {
  name                    = "cluster-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "cluster_subnet" {
  name          = "cluster-subnet"
  region        = var.region
  network       = google_compute_network.cluster_vpc.name
  ip_cidr_range = "10.1.0.0/24"
}

resource "google_compute_network" "mysql_vpc" {
  name                    = "mysql-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "mysql_subnet" {
  name          = "mysql-subnet"
  region        = var.region
  network       = google_compute_network.mysql_vpc.name
  ip_cidr_range = "10.2.0.0/24"
}

# --------------------------------------------------------------
# NAT router ---------------------------------------------------
# --------------------------------------------------------------

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "nat-router-for-gke"
  network = google_compute_network.cluster_vpc.name
  region  = var.region
}

module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 5.0"
  project_id                         = var.project_id
  region                             = var.region
  router                             = google_compute_router.router.name
  name                               = "nat-config-for-gke"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# --------------------------------------------------------------
# GKE cluster --------------------------------------------------
# --------------------------------------------------------------

resource "google_container_cluster" "primary" {
  name     = "gke-cluster"
  location = var.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.cluster_vpc.name
  subnetwork = google_compute_subnetwork.cluster_subnet.name

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes   = true 
    master_ipv4_cidr_block = "10.4.4.0/28"
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.5.0.0/21"
    services_ipv4_cidr_block = "10.6.0.0/21"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "${var.gke_bastion_ip}/32"
      display_name = "net1"
    }
  }
}

# Private Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name     = "gke-nodepool"
  location = var.zone
  cluster  = google_container_cluster.primary.name

  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    machine_type = "e2-standard-2"
    tags         = ["gke-node"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    disk_size_gb = 50
  }
}

resource "google_compute_instance" "gke-bastion" {
  zone         = var.zone
  name         = "gke-bastion-host"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  network_interface {
    network    = google_compute_network.cluster_vpc.name
    subnetwork = google_compute_subnetwork.cluster_subnet.name
    network_ip = var.gke_bastion_ip
    access_config {
    }
  }
}

resource "google_compute_firewall" "ssh-rule" {
  name    = "allow-ssh"
  network = google_compute_network.cluster_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}