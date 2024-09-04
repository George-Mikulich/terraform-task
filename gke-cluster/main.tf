resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.vpc
  subnetwork = var.subnet

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.cidr_master
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.cidr_pods
    services_ipv4_cidr_block = var.cidr_services
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "${var.bastion_internal_ip}/32"
      display_name = "net1"
    }
  }
}

# Private Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.cluster_name}-nodepool"
  location = var.zone
  cluster  = google_container_cluster.primary.name

  node_count = var.num_of_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "terraform-task"
    }

    machine_type = var.machine_type
    tags         = ["gke-node"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    disk_size_gb = var.disk_size_gb
  }
}

resource "google_compute_instance" "gke-bastion" {
  zone         = var.zone
  name         = "${var.cluster_name}-bastion"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  network_interface {
    network    = var.vpc
    subnetwork = var.subnet
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
apt-get install kubectl -y &&
apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y &&
export HOME=/home/guga &&
su guga -c "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project}" &&
kubectl proxy --port 443 --address 0.0.0.0 --accept-hosts "^*\.*\.*\.*$" &
EOT
  tags                    = ["gke-bastion-host", google_container_cluster.primary.name]
}

resource "google_compute_firewall" "ssh-rule" {
  name    = "allow-ssh"
  network = var.vpc
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "https-rule" {
  name    = "allow-https"
  network = var.vpc
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = ["${var.source_IP}"]
  source_tags   = ["gke-bastion-host"]
}