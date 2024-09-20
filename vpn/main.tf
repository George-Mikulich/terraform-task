resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  for_each = var.network
  region   = var.gcp_project_settings.region
  name     = "ha-vpn-${each.key}"
  network  = each.value.vpc_id
}

resource "google_compute_router" "router" {
  for_each = var.network
  name     = "ha-vpn-router-${each.key}"
  region   = var.gcp_project_settings.region
  network  = each.value.vpc_name
  bgp {
    advertise_mode    = "CUSTOM"
    asn               = each.value.asn
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = var.advertised_ip_range
    }
  }
}

resource "google_compute_vpn_tunnel" "gke_to_mysql_tunnel" {
  count                 = 2
  name                  = "ha-vpn-tunnel-gke-to-mysql-${count.index}"
  region                = var.gcp_project_settings.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway["gke"].id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway["mysql"].id
  shared_secret         = "a secret message"
  router                = google_compute_router.router["gke"].id
  vpn_gateway_interface = count.index
}

resource "google_compute_vpn_tunnel" "mysql_to_gke_tunnel" {
  count                 = 2
  name                  = "ha-vpn-tunnel-mysql-to-gke-${count.index}"
  region                = var.gcp_project_settings.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway["mysql"].id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway["gke"].id
  shared_secret         = "a secret message"
  router                = google_compute_router.router["mysql"].id
  vpn_gateway_interface = count.index
}

resource "google_compute_router_interface" "gke_router_interface" {
  count      = 2
  name       = "gke-router-interface${count.index}"
  router     = google_compute_router.router["gke"].name
  region     = var.gcp_project_settings.region
  ip_range   = "169.254.${count.index}.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.gke_to_mysql_tunnel[count.index].name
}

resource "google_compute_router_peer" "gke_router_peer" {
  count                     = 2
  name                      = "gke-router-peer${count.index}"
  router                    = google_compute_router.router["gke"].name
  region                    = var.gcp_project_settings.region
  peer_ip_address           = "169.254.${count.index}.2"
  peer_asn                  = var.network["mysql"].asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gke_router_interface[count.index].name
}

resource "google_compute_router_interface" "mysql_router_interface" {
  count      = 2
  name       = "mysql-router-interface${count.index}"
  router     = google_compute_router.router["mysql"].name
  region     = var.gcp_project_settings.region
  ip_range   = "169.254.${count.index}.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.mysql_to_gke_tunnel[count.index].name
}

resource "google_compute_router_peer" "mysql_router_peer" {
  count                     = 2
  name                      = "mysql-router-peer${count.index}"
  router                    = google_compute_router.router["mysql"].name
  region                    = var.gcp_project_settings.region
  peer_ip_address           = "169.254.${count.index}.1"
  peer_asn                  = var.network["gke"].asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.mysql_router_interface[count.index].name
}