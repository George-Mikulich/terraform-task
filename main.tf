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

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "7.1.1"
  create_namespace = true
  wait             = true
}

resource "helm_release" "nginx_ingress_controller" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = true
}

resource "helm_release" "external_secrets_preconfig" { #weakpoint
  name             = "eso-preconfig"
  chart            = "./secrets"
  namespace        = "external-secrets"
  create_namespace = true
  wait             = true
}

resource "helm_release" "external_secrets" {
  depends_on = [helm_release.external_secrets_preconfig]
  name       = "eso"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets"
  wait       = true
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  version          = "v1.15.1"
  create_namespace = true
  wait             = true
  values = [
    file("./custom-helm-values/cert-manager.yaml")
  ]
}

resource "helm_release" "dns_secret_key" {
  depends_on       = [helm_release.external_secrets, helm_release.cert_manager]
  name             = "external-secrets"
  repository       = "https://github.com/George-Mikulich/terraform-task"
  chart            = "helm-charts/eso"
  namespace        = "wordpress"
  create_namespace = true
  wait             = true
}

resource "helm_release" "issuer_and_certificate" {
  depends_on = [helm_release.dns_secret_key]
  name       = "issuer-and-certificate"
  repository = "https://github.com/George-Mikulich/terraform-task"
  chart      = "helm-charts/cert"
  namespace  = "ingress-nginx"
  wait       = true
}

# resource "helm_release" "wordpress" {
#   depends_on = [helm_release.dns_secret_key]
#   name       = "wordpress-app"
#   repository = "https://github.com/George-Mikulich/terraform-task"
#   chart      = "helm-charts/wordpress"
#   namespace  = "wordpress"
#   set {
#     name   = "host"
#     value = module.mysql-with-bastion.instance_ip
#   }
#   set {
#     name   = "database"
#     value = module.mysql-with-bastion.db_name
#   }
# }

resource "helm_release" "prometheus_grafana" {
  name             = "monitoring1"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  wait             = true
}

resource "helm_release" "uptime" {
  name       = "monitoring2"
  repository = "https://helm.irsigler.cloud"
  chart      = "uptime-kuma"
  namespace  = "monitoring"
  wait       = true
}