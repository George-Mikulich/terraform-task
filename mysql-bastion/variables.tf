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

variable "network" {
  type = object({
    vpc_name     = string
    vpc_selflink = string
    subnet_name  = string
  })
  default = {
    vpc_name     = "mysql-network-vpc"
    vpc_selflink = "хрен его знает"
    subnet_name  = "mysql-network-subnet"
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
    db_version          = string
    bastion_internal_ip = string
  })
  default = {
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