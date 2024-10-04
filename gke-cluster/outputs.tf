output "bastion_endpoint" {
  value = google_compute_instance.gke-bastion.network_interface[0].access_config[0].nat_ip
}

output "cert" {
  value = google_container_cluster.primary.master_auth[0].client_certificate
}

output "key" {
  value = google_container_cluster.primary.master_auth[0].client_key
  sensitive = true
}

output "ca_cert" {
  value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}