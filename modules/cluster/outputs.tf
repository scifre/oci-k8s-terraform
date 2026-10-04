output "cluster_id" {
  description = "OCID of the OKE cluster."
  value       = oci_containerengine_cluster.k8s.id
}

output "kubernetes_version" {
  description = "Kubernetes version of the cluster."
  value       = oci_containerengine_cluster.k8s.kubernetes_version
}

output "public_endpoint" {
  description = "Public API server endpoint."
  value       = oci_containerengine_cluster.k8s.endpoints[0].public_endpoint
}

output "private_endpoint" {
  description = "Private API server endpoint."
  value       = oci_containerengine_cluster.k8s.endpoints[0].private_endpoint
}
