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
  subnet_cidr_range = var.cidr_gke_subnet
}

module "mysql_network" {
  source            = "./vpc-subnets"
  region            = var.region
  name_prefix       = "mysql"
  subnet_cidr_range = var.cidr_mysql_subnet
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

module "mysql-with-bastion" {
  source                     = "./mysql-bastion"
  vpc_selflink               = module.mysql_network.vpc_selflink
  vpc_name                   = module.mysql_network.vpc_name
  region                     = var.region
  db_version                 = "MYSQL_8_0"
  firewall_allow_cidr_ranges = [var.cidr_gke_subnet, var.cidr_pods]
  bastion_subnet             = module.mysql_network.subnet_name
  bastion_internal_ip        = "10.2.0.10"
  db_user                    = var.db_user
  db_password                = var.db_password
}

# --------------------------------------------------------------
# VPN connection between 2 VPCs --------------------------------
# --------------------------------------------------------------

module "gke-mysql-vpn" {
  source              = "./vpn"
  gke_vpc_id          = module.gke_network.vpc_id
  mysql_vpc_id        = module.mysql_network.vpc_id
  gke_vpc_name        = module.gke_network.vpc_name
  mysql_vpc_name      = module.mysql_network.vpc_name
  region              = var.region
  advertised_ip_range = module.mysql-with-bastion.instances_ip_range
}

# --------------------------------------------------------------
# Helm Releases ------------------------------------------------
# --------------------------------------------------------------

# provider "helm" { #old provider
#   kubernetes {
#     config_path = "~/.kube/config"
#     #proxy_url   = "http://${google_compute_instance.gke-bastion.network_interface[0].access_config[0].nat_ip}:443"
#   }
# }

data "google_client_config" "default" {
}

# provider "helm" {
#   kubernetes {
#     host                   = module.private-gke-cluster.bastion_endpoint
#     token                  = data.google_client_config.default.access_token
#     client_certificate     = base64decode(module.private-gke-cluster.cert)
#     client_key             = base64decode(module.private-gke-cluster.key)
#     cluster_ca_certificate = base64decode(module.private-gke-cluster.ca_cert)
#   }
# }

# resource "helm_release" "argocd" {
#   name = "argocd"

#   repository       = "https://argoproj.github.io/argo-helm"
#   chart            = "argo-cd"
#   namespace        = "argocd"
#   version          = "7.1.1"
#   create_namespace = true
# }