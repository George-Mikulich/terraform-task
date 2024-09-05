variable "vpc_selflink" {
  type        = string
  description = "selflink to mysql vpc"
}

variable "region" {
  default     = "us-west1"
  description = "gcp region"
}

variable "db_version" {
  default     = "MYSQL_8_0"
  description = "(optional) describe your variable"
}

variable "firewall_allow_cidr_ranges" {
  default     = [""]
  description = "CIDR ranges allowed to connect to mysql VPC"
}