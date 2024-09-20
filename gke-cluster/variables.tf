variable "network" {
  type = object({
    vpc_name    = string
    subnet_name = string
  })
  default = {
    vpc_name    = "gke-network-vpc"
    subnet_name = "gke-network-subnet"
  }
}

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

variable "cluster_np_bastion_config" {
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
  }
}