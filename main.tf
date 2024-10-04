# Bucket for terraform state file.
# Commented after creating to disable message 'can't delete bucket'

# module "tfstate" {
#     source = "./tfstate-bucket"
# }

# --------------------------------------------------------------
# VPC networks and subnets -------------------------------------
# --------------------------------------------------------------

module "network" {
  source            = "./vpc-subnets"
  region            = var.gcp_project_settings.region
  for_each          = var.vpc_networks
  name_prefix       = each.value.name_prefix
  subnet_cidr_range = each.value.cidr_range
}

# --------------------------------------------------------------
# NAT router ---------------------------------------------------
# --------------------------------------------------------------

resource "google_compute_router" "router" {
  project = var.gcp_project_settings.project_id
  name    = "nat-router-for-gke"
  network = module.network["gke"].vpc_name
  region  = var.gcp_project_settings.region
}

module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 5.0"
  project_id                         = var.gcp_project_settings.project_id
  region                             = var.gcp_project_settings.region
  router                             = google_compute_router.router.name
  name                               = "nat-config-for-gke"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# --------------------------------------------------------------
# GKE cluster --------------------------------------------------
# --------------------------------------------------------------

module "private-gke-cluster" {
  source               = "./gke-cluster"
  gcp_project_settings = var.gcp_project_settings
  network = {
    vpc_name    = module.network["gke"].vpc_name
    subnet_name = module.network["gke"].subnet_name
  }
  cluster_np_bastion_config = var.gke_config
  tcp_firewall_config = {
    ssh   = var.tcp_firewall_config["ssh"]
    https = var.tcp_firewall_config["https"]
  }
}

# --------------------------------------------------------------
# MySQL DB with bastion ----------------------------------------
# --------------------------------------------------------------

module "mysql-with-bastion" {
  source               = "./mysql-bastion"
  gcp_project_settings = var.gcp_project_settings
  network = {
    vpc_name     = module.network["mysql"].vpc_name
    vpc_selflink = module.network["mysql"].vpc_selflink
    subnet_name  = module.network["mysql"].subnet_name
  }
  tcp_firewall_config = {
    ssh   = var.tcp_firewall_config["ssh"]
    mysql = var.tcp_firewall_config["mysql"]
  }
  db_config = var.db_config
  db_creds  = var.db_creds
}

# --------------------------------------------------------------
# VPN connection between 2 VPCs --------------------------------
# --------------------------------------------------------------

module "gke-mysql-vpn" {
  source = "./vpn"
  network = {
    gke = {
      vpc_name = module.network["gke"].vpc_name
      vpc_id   = module.network["gke"].vpc_id
      asn      = var.vpc_networks["gke"].asn
    }
    mysql = {
      vpc_name = module.network["mysql"].vpc_name
      vpc_id   = module.network["mysql"].vpc_id
      asn      = var.vpc_networks["mysql"].asn
    }
  }
  gcp_project_settings = var.gcp_project_settings
  advertised_ip_range  = module.mysql-with-bastion.instances_ip_range
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

module "helm_releases" {
  source       = "./helm-releases"
  helm_configs = var.helm_releases
}

module "dns" {
  source = "./dns"
  dns_config = var.dns_config
}
