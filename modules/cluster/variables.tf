variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment."
}

variable "cluster_name" {
  type        = string
  description = "Name of the OKE cluster."
  default     = "k8s-cluster-01"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the cluster."
}

variable "vcn_id" {
  type        = string
  description = "OCID of the VCN."
}

variable "public_subnet_id" {
  type        = string
  description = "OCID of the public subnet hosting the API endpoint."
}

variable "api_endpoint_nsg_id" {
  type        = string
  description = "OCID of the NSG attached to the API endpoint."
}
