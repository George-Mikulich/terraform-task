variable "name_prefix" {
  default     = "my"
  description = "prefix to add to vpc and subnet name"
}

variable "region" {
  default     = "us-west1"
  description = "gcp region"
}

variable "subnet_cidr_range" {
  default     = "10.0.0.0/24"
  description = "CIDR range for subnet"
}