resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_selflink
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_selflink
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database" "database" {
  name     = "mysql-db"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database_instance" "instance" {
  name             = "mysql-db-instance"
  region           = var.region
  database_version = var.db_version

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_selflink
      enable_private_path_for_google_cloud_services = true
    }
  }

  deletion_protection = "false"
}

resource "google_compute_firewall" "mysql-from-x-rule" {
  name    = "allow-mysql-from-specified-ranges"
  network = var.vpc_selflink
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_ranges = var.firewall_allow_cidr_ranges
}