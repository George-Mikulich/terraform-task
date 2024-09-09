output "instances_ip_range" {
  value = "${google_compute_global_address.private_ip_address.address}/${google_compute_global_address.private_ip_address.prefix_length}"
}

output "instance_ip" {
  value = "change me"
}

output "db_name" {
  value = google_sql_database.database.name
}