resource "google_compute_network_peering" "peering1" {
  name                 = "peering1to2"
  export_custom_routes = true
  import_custom_routes = true
  network              = var.vpc1
  peer_network         = var.vpc2
}

resource "google_compute_network_peering" "peering2" {
  name                 = "peering2to1"
  export_custom_routes = true
  import_custom_routes = true
  network              = var.vpc2
  peer_network         = var.vpc1
}