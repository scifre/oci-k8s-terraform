###############################################################################
# Data sources
###############################################################################

# Availability domains for placement configuration.
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# OKE-supported node source images for this cluster; used to resolve the
# image display name to an OCID (portable across regions/tenancies).
data "oci_containerengine_node_pool_option" "options" {
  node_pool_option_id = var.cluster_id
  compartment_id      = var.compartment_ocid
}

locals {
  # Match the requested image display name against available OKE sources.
  matching_image_ids = [
    for src in data.oci_containerengine_node_pool_option.options.sources :
    src.image_id if src.source_name == var.node_image_name
  ]

  node_image_id = length(local.matching_image_ids) > 0 ? local.matching_image_ids[0] : null
}

###############################################################################
# Node pool
###############################################################################

resource "oci_containerengine_node_pool" "k8s_free_np" {
  cluster_id         = var.cluster_id
  compartment_id     = var.compartment_ocid
  name               = var.node_pool_name
  kubernetes_version = var.kubernetes_version
  node_shape         = var.node_shape

  # Emulation type for the physical NIC.
  network_launch_type = "PARAVIRTUALIZED"

  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_in_gbs
  }

  node_source_details {
    source_type             = "IMAGE"
    image_id                = local.node_image_id
    boot_volume_size_in_gbs = var.node_boot_volume_size_in_gbs
  }

  node_config_details {
    size    = var.node_count
    nsg_ids = [var.np_nsg_id]

    # OCI VCN-native pod networking.
    node_pool_pod_network_option_details {
      cni_type       = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids = [var.private_subnet_id]
      pod_nsg_ids    = [var.np_nsg_id]
    }

    # One placement config per availability domain; all use the private subnet.
    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.ads.availability_domains
      content {
        availability_domain = placement_configs.value.name
        subnet_id           = var.private_subnet_id
      }
    }

    # Node identity tag: k8s.worker = "true"
    defined_tags = {
      (var.worker_defined_tag_key) = "true"
    }
  }

  node_eviction_node_pool_settings {
    eviction_grace_duration = var.node_eviction_grace_duration
  }
}
