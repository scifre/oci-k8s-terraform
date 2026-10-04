output "vcn_id" {
  description = "OCID of the VCN."
  value       = oci_core_vcn.k8s_vcn.id
}

output "public_subnet_id" {
  description = "OCID of the public subnet."
  value       = oci_core_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "OCID of the private subnet."
  value       = oci_core_subnet.private_subnet.id
}

output "lb_nsg_id" {
  description = "OCID of the load balancer NSG."
  value       = oci_core_network_security_group.lb_nsg.id
}

output "np_nsg_id" {
  description = "OCID of the node pool NSG."
  value       = oci_core_network_security_group.np_nsg.id
}

output "api_endpoint_nsg_id" {
  description = "OCID of the API endpoint NSG."
  value       = oci_core_network_security_group.api_endpoint_nsg.id
}
