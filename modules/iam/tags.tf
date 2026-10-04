###############################################################################
# Tag namespace & key
###############################################################################

resource "oci_identity_tag_namespace" "k8s" {
  compartment_id = var.compartment_ocid
  name           = "k8s"
  description    = "Tag namespace for OKE worker node identity."
}

resource "oci_identity_tag" "worker" {
  tag_namespace_id = oci_identity_tag_namespace.k8s.id
  name             = "worker"
  description      = "Marks OKE worker nodes (string value)."
}
