variable "gcp_project_settings" {
  type = object({
    zone       = string
    region     = string
    project_id = string
  })
  default = {
    zone       = "us-west1-c"
    region     = "us-west1"
    project_id = "my-beautiful-cluster2"
  }
}

variable "vpc_networks" {
  type = map(object({
    name_prefix = string
    cidr_range  = string
    asn         = number
  }))
  default = {
    gke = {
      name_prefix = "gke-network"
      cidr_range  = "10.1.0.0/24"
      asn         = 64514
    }
    mysql = {
      name_prefix = "mysql-network"
      cidr_range  = "10.2.0.0/24"
      asn         = 64515
    }
  }
  description = "VPC configuration variables"
}

variable "gke_config" {
  type = object({
    cluster_name = string
    cidr_ranges = object({
      pods     = string
      master   = string
      services = string
    })
    num_of_nodes        = number
    node_machine_type   = string
    node_disk_size_gb   = number
    bastion_internal_ip = string
  })
  description = "GKE cluster and NodePool configuration variables"
  default = {
    cluster_name = "mycluster"
    cidr_ranges = {
      pods     = "10.5.0.0/21"
      master   = "10.4.4.0/28"
      services = "10.6.0.0/21"
    }
    num_of_nodes        = 2
    node_machine_type   = "e2-standard-2"
    node_disk_size_gb   = 50
    bastion_internal_ip = "10.1.0.10"
  }
}

variable "tcp_firewall_config" {
  type = map(object({
    port          = number
    source_tags   = list(string)
    source_ranges = map(string)
  }))
  description = "Config variables for TCP protocol firewalls"
  default = {
    ssh = {
      port        = 22
      source_tags = null
      source_ranges = {
        all_IPs = "0.0.0.0/0"
      }
    }
    https = {
      port        = 443
      source_tags = ["gke-bastion-host"]
      source_ranges = {
        office_IP = "134.17.27.135/32"
        home_IP   = "178.125.239.2/32"
        bsu_IP    = "217.21.43.190/32"
      }
    }
    mysql = {
      port        = 3306
      source_tags = null
      source_ranges = {
        gke_pods   = "10.5.0.0/21"
        gke_subnet = "10.1.0.0/24"
      }
    }
  }
}

variable "db_config" {
  type = object({
    db_name             = string
    db_version          = string
    bastion_internal_ip = string
  })
  default = {
    db_name             = "mysql-db"
    db_version          = "MYSQL_8_0"
    bastion_internal_ip = "10.2.0.10"
  }
}

variable "db_creds" {
  type = object({
    user     = string
    password = string
  })
  sensitive = true
}

variable "helm_releases" {
  type = map(object({
    dependency_level = number
    create_namespace = bool
    wait             = bool
    release_name     = string
    repo             = string
    chart            = string
    namespace        = string
    version          = string
    values           = map(string)
  }))
  default = {
    argocd = {
      dependency_level = 0
      create_namespace = true
      wait             = true
      release_name     = "argocd"
      repo             = "https://argoproj.github.io/argo-helm"
      chart            = "argo-cd"
      namespace        = "argocd"
      version          = "7.1.1"
      values           = {}
    }
    nginx = {
      dependency_level = 0
      create_namespace = true
      wait             = true
      release_name     = "ingress-nginx"
      repo             = "https://kubernetes.github.io/ingress-nginx"
      chart            = "ingress-nginx"
      namespace        = "ingress-nginx"
      version          = ""
      values           = {}
    }
    prometheus_grafana = {
      dependency_level = 0
      create_namespace = true
      wait             = true
      release_name     = "monitoring1"
      repo             = "https://prometheus-community.github.io/helm-charts"
      chart            = "kube-prometheus-stack"
      namespace        = "monitoring"
      version          = ""
      values           = {}
    }
    uptime = {
      dependency_level = 0
      create_namespace = false
      wait             = true
      release_name     = "monitoring2"
      repo             = "https://helm.irsigler.cloud"
      chart            = "uptime-kuma"
      namespace        = "monitoring"
      version          = ""
      values           = {}
    }
    external_secrets_preconfig = {
      dependency_level = 0
      create_namespace = true
      wait             = true
      release_name     = "eso-preconfig"
      repo             = ""
      chart            = "./secrets"
      namespace        = "external-secrets"
      version          = ""
      values           = {}
    }
    cert_manager = {
      dependency_level = 0
      create_namespace = true
      wait             = true
      release_name     = "cert-manager"
      repo             = "https://charts.jetstack.io"
      chart            = "cert-manager"
      namespace        = "cert-manager"
      version          = "v1.15.1"
      values = {
        "crds.enabled" = true
        "crds.keep"    = false
      }
    }
    external_secrets = {
      dependency_level = 1
      create_namespace = false
      wait             = true
      release_name     = "eso"
      repo             = "https://charts.external-secrets.io"
      chart            = "external-secrets"
      namespace        = "external-secrets"
      version          = ""
      values           = {}
    }
    dns_secret_key = {
      dependency_level = 2
      create_namespace = true
      wait             = true
      release_name     = "external-secrets"
      repo             = "https://github.com/George-Mikulich/terraform-task"
      chart            = "helm-charts/eso"
      namespace        = "wordpress"
      version          = ""
      values           = {}
    }
    issuer_and_certificate = {
      dependency_level = 3
      create_namespace = false
      wait             = true
      release_name     = "issuer-and-certificate"
      repo             = "https://github.com/George-Mikulich/terraform-task"
      chart            = "helm-charts/cert"
      namespace        = "ingress-nginx"
      version          = ""
      values           = {}
    }
    wordpress = {
      dependency_level = 3
      create_namespace = false
      wait             = true
      release_name     = "wordpress-app"
      repo             = "https://github.com/George-Mikulich/terraform-task"
      chart            = "helm-charts/wordpress"
      namespace        = "wordpress"
      version          = "0.0.0"
      values = {
        host     = "10.121.104.3"
        database = "mysql-db"
      }
    }

    empty = {
      dependency_level = 1000
      create_namespace = false
      wait             = false
      release_name     = "empty"
      repo             = ""
      chart            = ""
      namespace        = ""
      version          = ""
      values           = {}
    }
  }
}