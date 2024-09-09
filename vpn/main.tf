resource "google_compute_ha_vpn_gateway" "ha_gateway1" {
  region  = var.region
  name    = "ha-vpn-mysql"
  network = var.gke_vpc_id
}

resource "google_compute_ha_vpn_gateway" "ha_gateway2" {
  region  = var.region
  name    = "ha-vpn-gke"
  network = var.mysql_vpc_id
}

resource "google_compute_router" "router1" {
  name    = "ha-vpn-router-gke"
  region  = var.region
  network = var.gke_vpc_name
  bgp {
    advertise_mode    = "CUSTOM"
    asn               = 64514
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = var.advertised_ip_range
    }
  }
}

resource "google_compute_router" "router2" {
  name    = "ha-vpn-router-mysql"
  region  = var.region
  network = var.mysql_vpc_name
  bgp {
    advertise_mode    = "CUSTOM"
    asn               = 64515
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = var.advertised_ip_range
    }
  }
}

resource "google_compute_vpn_tunnel" "tunnel1" {
  name                  = "ha-vpn-tunnel1"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway1.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router1.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  name                  = "ha-vpn-tunnel2"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway1.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router1.id
  vpn_gateway_interface = 1
}

resource "google_compute_vpn_tunnel" "tunnel3" {
  name                  = "ha-vpn-tunnel3"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway1.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel4" {
  name                  = "ha-vpn-tunnel4"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway1.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 1
}

resource "google_compute_router_interface" "router1_interface1" {
  name       = "router1-interface1"
  router     = google_compute_router.router1.name
  region     = var.region
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "router1_peer1" {
  name                      = "router1-peer1"
  router                    = google_compute_router.router1.name
  region                    = var.region
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface1.name
}

resource "google_compute_router_interface" "router1_interface2" {
  name       = "router1-interface2"
  router     = google_compute_router.router1.name
  region     = var.region
  ip_range   = "169.254.1.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "router1_peer2" {
  name                      = "router1-peer2"
  router                    = google_compute_router.router1.name
  region                    = var.region
  peer_ip_address           = "169.254.1.1"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface2.name
}

resource "google_compute_router_interface" "router2_interface1" {
  name       = "router2-interface1"
  router     = google_compute_router.router2.name
  region     = var.region
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel3.name
}

resource "google_compute_router_peer" "router2_peer1" {
  name                      = "router2-peer1"
  router                    = google_compute_router.router2.name
  region                    = var.region
  peer_ip_address           = "169.254.0.1"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_interface1.name
}

resource "google_compute_router_interface" "router2_interface2" {
  name       = "router2-interface2"
  router     = google_compute_router.router2.name
  region     = var.region
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel4.name
}

resource "google_compute_router_peer" "router2_peer2" {
  name                      = "router2-peer2"
  router                    = google_compute_router.router2.name
  region                    = var.region
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_interface2.name
}