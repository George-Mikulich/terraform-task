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

resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.instance.name
  host     = var.bastion_internal_ip
  password = var.db_password
}

resource "google_compute_instance" "mysql_bastion" {
  zone         = var.zone
  name         = "mysql-bastion"
  machine_type = "e2-standard-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  network_interface {
    network    = var.vpc_name
    subnetwork = var.bastion_subnet
    network_ip = var.bastion_internal_ip
    access_config {
    }
  }
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = "gke-bastion@my-beautiful-cluster2.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = <<EOT
apt-get install default-mysql-client --assume-yes
EOT
  tags                    = ["mysql-bastion-host"]
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

resource "google_compute_firewall" "ssh-rule" {
  name    = "allow-ssh-mysql-bastion"
  network = var.vpc_name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}