variable "region" {
  default     = "us-west1"
  description = "LOL are you serious"
}

variable "mysql_vpc_id" {
  type = string
}

variable "gke_vpc_id" {
  type = string
}

variable "mysql_vpc_name" {
  type = string
}

variable "gke_vpc_name" {
  type = string
}

variable "advertised_ip_range" {
  type        = string
  description = "cidr range of mysql instances; goes to gke ha-vpn router"
}