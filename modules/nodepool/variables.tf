variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment."
}

variable "tenancy_ocid" {
  type        = string
  description = "OCID of the tenancy (used to list availability domains)."
}

variable "cluster_id" {
  type        = string
  description = "OCID of the OKE cluster this node pool attaches to."
}

variable "node_pool_name" {
  type        = string
  description = "Name of the node pool."
  default     = "k8s-free-np"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the node pool."
}

variable "private_subnet_id" {
  type        = string
  description = "OCID of the private subnet for worker nodes and pods."
}

variable "np_nsg_id" {
  type        = string
  description = "OCID of the worker node NSG."
}

variable "node_image_name" {
  type        = string
  description = "Display name of the OKE node image to look up."
}

variable "node_shape" {
  type        = string
  description = "Compute shape for worker nodes."
  default     = "VM.Standard.A1.Flex"
}

variable "node_ocpus" {
  type        = number
  description = "OCPUs per node."
  default     = 1
}

variable "node_memory_in_gbs" {
  type        = number
  description = "Memory in GB per node."
  default     = 6
}

variable "node_boot_volume_size_in_gbs" {
  type        = number
  description = "Boot volume size in GB per node."
  default     = 90
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the node pool."
  default     = 2
}

variable "node_eviction_grace_duration" {
  type        = string
  description = "ISO 8601 eviction grace duration (e.g. PT60M)."
  default     = "PT60M"
}

variable "worker_defined_tag_key" {
  type        = string
  description = "Fully-qualified defined tag key (namespace.key) to apply to nodes, value 'true'."
}
