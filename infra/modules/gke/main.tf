resource "google_container_cluster" "primary" {
  name               = var.name
  location           = var.region
  initial_node_count = var.initial_node_count

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  remove_default_node_pool = false
  deletion_protection = false
}
