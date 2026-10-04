###############################################################################
# VCN
###############################################################################

resource "oci_core_vcn" "k8s_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "k8s-vcn"
  dns_label      = "k8svcn"
}

###############################################################################
# Gateways
###############################################################################

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-vcn-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-vcn-nat"
  # A public IP is automatically allocated to the NAT gateway by OCI.
}

# Resolve the "All <region> Services In Oracle Services Network" service target
# used by the service gateway. Selecting the entry whose name contains
# "Services In Oracle Services Network" gives the all-services CIDR label.
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-vcn-sgw"

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

###############################################################################
# Subnets
###############################################################################

resource "oci_core_subnet" "public_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.k8s_vcn.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public_rt.id
  security_list_ids          = [oci_core_vcn.k8s_vcn.default_security_list_id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "private_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.k8s_vcn.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "private-subnet"
  dns_label                  = "private"
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_vcn.k8s_vcn.default_security_list_id]
  prohibit_public_ip_on_vnic = true
}
