variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where network resources are created."
}

variable "vcn_cidr" {
  type        = string
  description = "CIDR block for the VCN."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet (LBs + API endpoint)."
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet (worker nodes)."
  default     = "10.0.2.0/24"
}

variable "api_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the Kubernetes API endpoint on TCP 6443. Empty creates no external rule."
  default     = []
}
