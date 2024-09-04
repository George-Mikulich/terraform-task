# Bucket for terraform state file.
# Commented after creating to disable message 'can't delete bucket'

# module "tfstate" {
#     source = "./tfstate-bucket"
# }

# --------------------------------------------------------------
# VPC networks and subnets -------------------------------------
# --------------------------------------------------------------

module "gke_network" {
  source            = "./vpc-subnets"
  region            = var.region
  name_prefix       = "cluster"
  subnet_cidr_range = "10.1.0.0/24"
}

module "mysql_network" {
  source            = "./vpc-subnets"
  region            = var.region
  name_prefix       = "mysql"
  subnet_cidr_range = "10.2.0.0/24"
}

# --------------------------------------------------------------
# NAT router ---------------------------------------------------
# --------------------------------------------------------------

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "nat-router-for-gke"
  network = module.gke_network.vpc_name
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

module "private-gke-cluster" {
  source              = "./gke-cluster"
  cluster_name        = "terraform-task-cluster"
  zone                = var.zone
  project             = var.project_id
  vpc                 = module.gke_network.vpc_name
  subnet              = module.gke_network.subnet_name
  cidr_master         = "10.4.4.0/28"
  cidr_pods           = var.cidr_pods
  cidr_services       = "10.6.0.0/21"
  bastion_internal_ip = "10.1.0.10"
  num_of_nodes        = var.gke_num_nodes
  machine_type        = "e2-standard-2"
  disk_size_gb        = 50
}

# --------------------------------------------------------------
# MySQL DB with bastion ----------------------------------------
# --------------------------------------------------------------

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.mysql_network.vpc_selflink
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.mysql_network.vpc_selflink
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database" "database" {
  name     = "mysql-db"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database_instance" "instance" {
  name             = "mysql-db-instance"
  region           = var.region
  database_version = "MYSQL_8_0"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = module.mysql_network.vpc_selflink
      enable_private_path_for_google_cloud_services = true
    }
  }

  deletion_protection = "false"
}

resource "google_compute_network_peering" "peering1" {
  name         = "peering1"
  export_custom_routes = true
  import_custom_routes = true
  network      = module.gke_network.vpc_selflink
  peer_network = module.mysql_network.vpc_selflink
}

resource "google_compute_network_peering" "peering2" {
  name         = "peering2"
  export_custom_routes = true
  import_custom_routes = true
  network      = module.mysql_network.vpc_selflink
  peer_network = module.gke_network.vpc_selflink
}

resource "google_compute_firewall" "mysql-from-pods-rule" {
  name    = "allow-mysql-from-pods"
  network = module.mysql_network.vpc_selflink
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_ranges = ["${var.cidr_pods}"]
}

resource "google_compute_firewall" "mysql-from-ce" {
  name    = "allow-mysql-from-ce"
  network = module.mysql_network.vpc_selflink
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_ranges = ["10.1.0.0/24"]
}

# --------------------------------------------------------------
# Helm Releases ------------------------------------------------
# --------------------------------------------------------------

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    #proxy_url   = "http://${google_compute_instance.gke-bastion.network_interface[0].access_config[0].nat_ip}:443"
  }
}

# resource "helm_release" "argocd" {
#   name = "argocd"

#   repository       = "https://argoproj.github.io/argo-helm"
#   chart            = "argo-cd"
#   namespace        = "argocd"
#   version          = "7.1.1"
#   create_namespace = true
# }