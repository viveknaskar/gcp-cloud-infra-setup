output "gke_cluster_name" {
  description = "The name of the GKE cluster."
  value       = module.gke_cluster.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster."
  value       = module.gke_cluster.cluster_endpoint
}

output "vpc_network_self_link" {
  description = "The self_link of the created VPC network."
  value       = module.network.network_self_link
}

# Add other outputs like DB connection strings, Secret Manager IDs, etc.