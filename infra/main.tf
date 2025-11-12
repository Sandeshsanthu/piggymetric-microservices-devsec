provider "google" {
  project = var.project_id
  region  = var.region
}

module "gke" {
  source             = "./modules/gke"
  project_id         = var.project_id
  region             = var.region
  name               = var.gke_name
  initial_node_count = var.gke_node_count
  node_machine_type  = var.gke_node_machine_type
  node_disk_size_gb = var.gke_node_disk_size_gb
  node_disk_type    = var.gke_node_disk_type
}
