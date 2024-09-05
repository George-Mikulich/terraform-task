variable "vpc_selflink" {
  type        = string
  description = "selflink to mysql vpc"
}

variable "vpc_name" {
  type        = string
  description = "name of mysql vpc"
}

variable "region" {
  default     = "us-west1"
  description = "gcp region"
}

variable "zone" {
  default     = "us-west1-c"
  description = "gcp zone"
}

variable "db_version" {
  default     = "MYSQL_8_0"
  description = "(optional) describe your variable"
}

variable "firewall_allow_cidr_ranges" {
  default     = [""]
  description = "CIDR ranges allowed to connect to mysql VPC"
}

variable "bastion_subnet" {
  type        = string
  description = "self-descriptive"
}

variable "bastion_internal_ip" {
  type        = string
  description = "self-descriptive"
}

variable "db_user" {
  type        = string
  sensitive   = true
  description = ""
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = ""
}