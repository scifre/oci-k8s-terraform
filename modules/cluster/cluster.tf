###############################################################################
# OKE cluster with a public API endpoint
###############################################################################

resource "oci_containerengine_cluster" "k8s" {
  compartment_id     = var.compartment_ocid
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vcn_id             = var.vcn_id

  endpoint_config {
    subnet_id            = var.public_subnet_id
    nsg_ids              = [var.api_endpoint_nsg_id]
    is_public_ip_enabled = true
  }
}
