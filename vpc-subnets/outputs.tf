output "vpc_name" {
  value = google_compute_network.default_vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.default_subnet.name
}

output "vpc_selflink" {
  value = google_compute_network.default_vpc.self_link
}

output "vpc_id" {
  value = google_compute_network.default_vpc.id
}