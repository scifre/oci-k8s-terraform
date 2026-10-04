###############################################################################
# Network Security Groups
###############################################################################

resource "oci_core_network_security_group" "lb_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-lb-nsg"
}

resource "oci_core_network_security_group" "np_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-np-nsg"
}

resource "oci_core_network_security_group" "api_endpoint_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-api-endpoint-nsg"
}

###############################################################################
# k8s-lb-nsg rules
#   a. Ingress 0.0.0.0/0 TCP dest 443
#   b. Ingress 0.0.0.0/0 TCP dest 80
#   c. Egress  -> k8s-np-nsg all protocols
###############################################################################

resource "oci_core_network_security_group_security_rule" "lb_ingress_443" {
  network_security_group_id = oci_core_network_security_group.lb_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_ingress_80" {
  network_security_group_id = oci_core_network_security_group.lb_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_egress_to_np" {
  network_security_group_id = oci_core_network_security_group.lb_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = oci_core_network_security_group.np_nsg.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

###############################################################################
# k8s-np-nsg rules
#   a. Ingress from k8s-np-nsg (self) all protocols
#   b. Egress 0.0.0.0/0 all protocols
#   c. Egress -> k8s-np-nsg (self) all protocols
#   d. Ingress from k8s-api-endpoint-nsg all protocols
#   e. Ingress 0.0.0.0/0 ICMP type 3 code 4
#   f. Ingress from k8s-lb-nsg TCP all ports
###############################################################################

resource "oci_core_network_security_group_security_rule" "np_ingress_self" {
  network_security_group_id = oci_core_network_security_group.np_nsg.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = oci_core_network_security_group.np_nsg.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "np_egress_internet" {
  network_security_group_id = oci_core_network_security_group.np_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "np_egress_self" {
  network_security_group_id = oci_core_network_security_group.np_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = oci_core_network_security_group.np_nsg.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "np_ingress_from_api" {
  network_security_group_id = oci_core_network_security_group.np_nsg.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = oci_core_network_security_group.api_endpoint_nsg.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "np_ingress_icmp" {
  network_security_group_id = oci_core_network_security_group.np_nsg.id
  direction                 = "INGRESS"
  protocol                  = "1" # ICMP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "np_ingress_from_lb" {
  network_security_group_id = oci_core_network_security_group.np_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = oci_core_network_security_group.lb_nsg.id
  source_type               = "NETWORK_SECURITY_GROUP"
  # No tcp_options => all TCP ports.
}

###############################################################################
# k8s-api-endpoint-nsg rules
#   a. Ingress from k8s-np-nsg all protocols
#   b. Egress  -> k8s-np-nsg all protocols
#   c. Ingress from k8s-api-endpoint-nsg (self) all protocols
#   d. Variable-driven ingress from api_allowed_cidrs TCP dest 6443
###############################################################################

resource "oci_core_network_security_group_security_rule" "api_ingress_from_np" {
  network_security_group_id = oci_core_network_security_group.api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = oci_core_network_security_group.np_nsg.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "api_egress_to_np" {
  network_security_group_id = oci_core_network_security_group.api_endpoint_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = oci_core_network_security_group.np_nsg.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "api_ingress_self" {
  network_security_group_id = oci_core_network_security_group.api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = oci_core_network_security_group.api_endpoint_nsg.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

# Variable-driven external access to the API endpoint on TCP 6443.
# One rule per allowed CIDR; none created when api_allowed_cidrs is empty.
resource "oci_core_network_security_group_security_rule" "api_ingress_6443" {
  for_each = toset(var.api_allowed_cidrs)

  network_security_group_id = oci_core_network_security_group.api_endpoint_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}
