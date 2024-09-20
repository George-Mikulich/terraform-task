resource "google_container_cluster" "primary" {
  name     = var.cluster_np_bastion_config.cluster_name
  location = var.gcp_project_settings.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network.vpc_name
  subnetwork = var.network.subnet_name

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.cluster_np_bastion_config.cidr_ranges.master
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.cluster_np_bastion_config.cidr_ranges.pods
    services_ipv4_cidr_block = var.cluster_np_bastion_config.cidr_ranges.services
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "${var.cluster_np_bastion_config.bastion_internal_ip}/32"
      display_name = "net1"
    }
  }
}

# Private Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.cluster_np_bastion_config.cluster_name}-nodepool"
  location = var.gcp_project_settings.zone
  cluster  = google_container_cluster.primary.name

  node_count = var.cluster_np_bastion_config.num_of_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "terraform-task"
    }

    machine_type = var.cluster_np_bastion_config.node_machine_type
    tags         = ["gke-node"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    disk_size_gb = var.cluster_np_bastion_config.node_disk_size_gb
  }
}

resource "google_compute_instance" "gke-bastion" {
  zone         = var.gcp_project_settings.zone
  name         = "${var.cluster_np_bastion_config.cluster_name}-bastion"
  machine_type = var.cluster_np_bastion_config.node_machine_type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  network_interface {
    network    = var.network.vpc_name
    subnetwork = var.network.subnet_name
    network_ip = var.cluster_np_bastion_config.bastion_internal_ip
    access_config {
    }
  }
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = "gke-bastion@my-beautiful-cluster2.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = <<EOT
apt-get install kubectl -y &&
apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y &&
export HOME=/home/guga &&
su guga -c "gcloud container clusters get-credentials ${var.cluster_np_bastion_config.cluster_name} --zone ${var.gcp_project_settings.zone} --project ${var.gcp_project_settings.project_id}" &&
kubectl proxy --port ${var.tcp_firewall_config["https"].port} --address 0.0.0.0 --accept-hosts "^*\.*\.*\.*$" &
EOT
  tags                    = ["gke-bastion-host", google_container_cluster.primary.name]
}

resource "google_compute_firewall" "firewall_rules" {
  for_each = var.tcp_firewall_config
  name     = "allow-${each.key}"
  network  = var.network.vpc_name
  allow {
    protocol = "tcp"
    ports    = ["${each.value.port}"]
  }
  source_ranges = [for cidr_range in each.value.source_ranges : cidr_range]
  source_tags   = each.value.source_tags
}