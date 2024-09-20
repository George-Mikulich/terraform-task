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
  type = map(object({
    vpc_name = string
    vpc_id   = string
    asn      = number
  }))
}

variable "advertised_ip_range" {
  type        = string
  description = "cidr range of mysql instances; goes to gke ha-vpn router"
}