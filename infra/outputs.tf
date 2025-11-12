output "kubernetes_cluster_name" {
  value = module.gke.name
}
output "kubernetes_endpoint" {
  value = module.gke.endpoint
}
output "client_certificate" {
  value = module.gke.master_auth.0.client_certificate
}
