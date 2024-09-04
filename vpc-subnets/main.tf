resource "google_compute_network" "default_vpc" {
  name                    = var.name_prefix
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default_subnet" {
  name          = var.name_prefix
  region        = var.region
  network       = google_compute_network.default_vpc.name
  ip_cidr_range = var.subnet_cidr_range
}