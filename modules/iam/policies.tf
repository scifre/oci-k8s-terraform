###############################################################################
# Dynamic group (created at tenancy/root level)
###############################################################################

resource "oci_identity_dynamic_group" "worker_nodes" {
  compartment_id = var.tenancy_ocid
  name           = "k8s-worker-nodes"
  description    = "OKE worker nodes identified by the k8s.worker tag."
  matching_rule  = "ALL {tag.k8s.worker.value = 'true'}"

  # Ensure the tag key exists before the matching rule references it.
  depends_on = [oci_identity_tag.worker]
}

###############################################################################
# Worker node policy (scoped to the compartment, minimal families)
###############################################################################

resource "oci_identity_policy" "worker_node_policy" {
  compartment_id = var.compartment_ocid
  name           = "k8s-worker-node-policy"
  description    = "Permissions required by OKE worker nodes, scoped to the compartment."

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.worker_nodes.name} to manage load-balancers in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.worker_nodes.name} to manage certificate-authority-family in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.worker_nodes.name} to manage leaf-certificate-family in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.worker_nodes.name} to use virtual-network-family in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.worker_nodes.name} to read clusters in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.worker_nodes.name} to read repos in compartment ${var.compartment_name}",
  ]
}

###############################################################################
# OKE service policy
#   Default: compartment-scoped minimal families.
#   oke_policy_broad = true: tenancy-wide manage all-resources (not recommended).
###############################################################################

locals {
  oke_service_statements_scoped = [
    "Allow service OKE to manage cluster-node-pools in compartment ${var.compartment_name}",
    "Allow service OKE to manage instance-family in compartment ${var.compartment_name}",
    "Allow service OKE to use subnets in compartment ${var.compartment_name}",
    "Allow service OKE to use vnics in compartment ${var.compartment_name}",
    "Allow service OKE to use private-ips in compartment ${var.compartment_name}",
    "Allow service OKE to use network-security-groups in compartment ${var.compartment_name}",
    "Allow service OKE to manage public-ips in compartment ${var.compartment_name}",
  ]

  oke_service_statements_broad = [
    "Allow service OKE to manage all-resources in tenancy",
  ]
}

resource "oci_identity_policy" "oke_service_policy" {
  compartment_id = var.oke_policy_broad ? var.tenancy_ocid : var.compartment_ocid
  name           = "oke-service-policy"
  description    = "Permissions for the OKE service."

  statements = var.oke_policy_broad ? local.oke_service_statements_broad : local.oke_service_statements_scoped
}
