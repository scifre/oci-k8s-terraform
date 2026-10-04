output "node_pool_id" {
  description = "OCID of the node pool."
  value       = oci_containerengine_node_pool.k8s_free_np.id
}

output "resolved_node_image_id" {
  description = "OCID of the resolved node image (null if the image name did not match)."
  value       = local.node_image_id
}
