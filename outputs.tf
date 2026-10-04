###############################################################################
# Network outputs
###############################################################################

output "vcn_id" {
  description = "OCID of the VCN."
  value       = module.network.vcn_id
}

output "public_subnet_id" {
  description = "OCID of the public subnet."
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "OCID of the private subnet."
  value       = module.network.private_subnet_id
}

output "lb_nsg_id" {
  description = "OCID of the load balancer NSG."
  value       = module.network.lb_nsg_id
}

output "np_nsg_id" {
  description = "OCID of the node pool NSG."
  value       = module.network.np_nsg_id
}

output "api_endpoint_nsg_id" {
  description = "OCID of the API endpoint NSG."
  value       = module.network.api_endpoint_nsg_id
}

###############################################################################
# Cluster outputs
###############################################################################

output "cluster_id" {
  description = "OCID of the OKE cluster."
  value       = module.cluster.cluster_id
}

output "cluster_public_endpoint" {
  description = "Public API server endpoint."
  value       = module.cluster.public_endpoint
}

output "cluster_private_endpoint" {
  description = "Private API server endpoint."
  value       = module.cluster.private_endpoint
}

###############################################################################
# Node pool outputs
###############################################################################

output "node_pool_id" {
  description = "OCID of the node pool."
  value       = module.nodepool.node_pool_id
}

###############################################################################
# IAM outputs
###############################################################################

output "worker_dynamic_group_name" {
  description = "Name of the worker nodes dynamic group."
  value       = module.iam.dynamic_group_name
}

output "worker_defined_tag_key" {
  description = "Defined tag key applied to worker nodes."
  value       = module.iam.worker_defined_tag_key
}

###############################################################################
# Convenience outputs (used by scripts/install-addons.sh)
###############################################################################

output "region" {
  description = "OCI region identifier."
  value       = var.region
}
