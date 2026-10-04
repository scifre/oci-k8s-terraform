variable "tenancy_ocid" {
  type        = string
  description = "OCID of the tenancy. Dynamic groups must be created at the tenancy (root) level."
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where the tag namespace and policies are created."
}

variable "compartment_name" {
  type        = string
  description = "Name of the compartment, used in policy statements scoped to the compartment."
}

variable "oke_policy_broad" {
  type        = bool
  description = "If true, grant OKE 'manage all-resources in tenancy'. Default false uses compartment-scoped minimal statements."
  default     = false
}
