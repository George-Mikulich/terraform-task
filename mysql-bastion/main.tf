resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 22
  network       = var.network.vpc_selflink
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.network.vpc_selflink
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  # export_custom_routes = true !!!
  # you need to do this manually, TF does not provide such argument for this resource
}

# trying to solve this ^^^ problem
resource "google_compute_network_peering_routes_config" "peering_primary_routes" {
  peering = google_service_networking_connection.private_vpc_connection
  network = var.network.vpc_selflink

  import_custom_routes = true
  export_custom_routes = true
}

resource "google_sql_database" "database" {
  name     = var.db_config.db_name
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database_instance" "instance" {
  name             = "${var.db_config.db_name}-instance"
  region           = var.gcp_project_settings.region
  database_version = var.db_config.db_version

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network.vpc_selflink
      enable_private_path_for_google_cloud_services = true
    }
  }
  deletion_protection = "false"
}

resource "google_sql_user" "users" {
  name     = var.db_creds.user
  instance = google_sql_database_instance.instance.name
  host     = "%"
  password = var.db_creds.password
}

resource "google_compute_instance" "mysql_bastion" {
  zone         = var.gcp_project_settings.zone
  name         = "mysql-bastion"
  machine_type = "e2-standard-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  network_interface {
    network    = var.network.vpc_name
    subnetwork = var.network.subnet_name
    network_ip = var.db_config.bastion_internal_ip
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

resource "google_compute_firewall" "firewall_rules" {
  for_each = var.tcp_firewall_config
  name     = "allow-${each.key}-mysql"
  network  = var.network.vpc_name
  allow {
    protocol = "tcp"
    ports    = ["${each.value.port}"]
  }
  source_ranges = [for cidr_range in each.value.source_ranges : cidr_range] #converting map to list
  source_tags   = each.value.source_tags
}