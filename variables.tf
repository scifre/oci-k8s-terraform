###############################################################################
# Provider authentication (API key auth via variables)
###############################################################################

variable "tenancy_ocid" {
  type        = string
  description = "OCID of the tenancy."
}

variable "user_ocid" {
  type        = string
  description = "OCID of the user used for API key authentication."
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint of the API signing key."
}

variable "private_key_path" {
  type        = string
  description = "Path to the PEM private key used for API key authentication."
}

variable "region" {
  type        = string
  description = "OCI region identifier (e.g. ap-mumbai-1 for BOM)."
  default     = "ap-mumbai-1"
}

###############################################################################
# Placement
###############################################################################

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where all resources are created."
}

###############################################################################
# Cluster
###############################################################################

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the OKE cluster and node pool."
  default     = "v1.36.1"
}

variable "cluster_name" {
  type        = string
  description = "Name of the OKE cluster."
  default     = "k8s-cluster-01"
}

variable "api_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the public Kubernetes API endpoint on TCP 6443. Empty means no external access rule is created. Do NOT set to 0.0.0.0/0 in production."
  default     = []
}

###############################################################################
# Node pool
###############################################################################

variable "node_pool_name" {
  type        = string
  description = "Name of the node pool."
  default     = "k8s-free-np"
}

variable "node_image_name" {
  type        = string
  description = "Exact OKE node image display name to look up (must match the platform image available in the region)."
  default     = "Oracle-Linux-8.10-aarch64-2026.08.14-0-OKE-1.36.1-1699"
}

variable "node_shape" {
  type        = string
  description = "Compute shape for worker nodes."
  default     = "VM.Standard.A1.Flex"
}

variable "node_ocpus" {
  type        = number
  description = "OCPUs per worker node (flex shape)."
  default     = 1
}

variable "node_memory_in_gbs" {
  type        = number
  description = "Memory in GB per worker node (flex shape)."
  default     = 6
}

variable "node_boot_volume_size_in_gbs" {
  type        = number
  description = "Boot volume size in GB per worker node."
  default     = 90
}

variable "node_count" {
  type        = number
  description = "Number of worker nodes in the node pool."
  default     = 2
}

variable "node_eviction_grace_duration" {
  type        = string
  description = "Node eviction grace duration as an ISO 8601 duration (e.g. PT60M for 60 minutes)."
  default     = "PT60M"
}

###############################################################################
# IAM
###############################################################################

variable "oke_policy_broad" {
  type        = bool
  description = "If true, grant the OKE service the broad 'manage all-resources in tenancy' statement. Default false uses compartment-scoped minimal statements (recommended)."
  default     = false
}
