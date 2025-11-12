variable "project_id" {default="sapient-reducer-477808-m0"}
variable "region" {}
variable "name" {}
variable "initial_node_count" {}
variable "node_machine_type" {}
variable "node_disk_size_gb" {
  default = 30
}
variable "node_disk_type" {
  default = "pd-standard"
}
