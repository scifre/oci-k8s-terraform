output "tag_namespace_id" {
  description = "OCID of the k8s tag namespace."
  value       = oci_identity_tag_namespace.k8s.id
}

output "worker_tag_id" {
  description = "OCID of the k8s.worker tag."
  value       = oci_identity_tag.worker.id
}

output "worker_defined_tag_key" {
  description = "Fully-qualified defined tag key (namespace.key) for node tagging."
  value       = "${oci_identity_tag_namespace.k8s.name}.${oci_identity_tag.worker.name}"
}

output "dynamic_group_name" {
  description = "Name of the worker nodes dynamic group."
  value       = oci_identity_dynamic_group.worker_nodes.name
}
