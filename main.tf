###############################################################################
# Provider
###############################################################################

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Resolve the compartment name for use in IAM policy statements.
data "oci_identity_compartment" "this" {
  id = var.compartment_ocid
}

###############################################################################
# IAM (tag namespace, dynamic group, policies)
# The tag namespace must exist before the node pool references its defined tag.
###############################################################################

module "iam" {
  source = "./modules/iam"

  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  compartment_name = data.oci_identity_compartment.this.name
  oke_policy_broad = var.oke_policy_broad
}

###############################################################################
# Network (VCN, subnets, gateways, route tables, NSGs)
###############################################################################

module "network" {
  source = "./modules/network"

  compartment_ocid  = var.compartment_ocid
  api_allowed_cidrs = var.api_allowed_cidrs
}

###############################################################################
# OKE cluster (public API endpoint in the public subnet)
###############################################################################

module "cluster" {
  source = "./modules/cluster"

  compartment_ocid    = var.compartment_ocid
  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  vcn_id              = module.network.vcn_id
  public_subnet_id    = module.network.public_subnet_id
  api_endpoint_nsg_id = module.network.api_endpoint_nsg_id
}

###############################################################################
# Node pool (workers in the private subnet)
###############################################################################

module "nodepool" {
  source = "./modules/nodepool"

  compartment_ocid             = var.compartment_ocid
  tenancy_ocid                 = var.tenancy_ocid
  cluster_id                   = module.cluster.cluster_id
  node_pool_name               = var.node_pool_name
  kubernetes_version           = var.kubernetes_version
  private_subnet_id            = module.network.private_subnet_id
  np_nsg_id                    = module.network.np_nsg_id
  node_image_name              = var.node_image_name
  node_shape                   = var.node_shape
  node_ocpus                   = var.node_ocpus
  node_memory_in_gbs           = var.node_memory_in_gbs
  node_boot_volume_size_in_gbs = var.node_boot_volume_size_in_gbs
  node_count                   = var.node_count
  node_eviction_grace_duration = var.node_eviction_grace_duration
  worker_defined_tag_key       = module.iam.worker_defined_tag_key
}
