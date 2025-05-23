resource "oci_core_vcn" "dayz_vcn" {
  compartment_id = oci_identity_compartment.dayz_compartment.id
  display_name   = "dayz-vcn"
  cidr_block     = "192.168.0.0/16"
}

resource "oci_core_subnet" "pub_subnet" {
  cidr_block     = "192.168.0.0/16"
  display_name   = "pub_subnet"
  compartment_id = oci_identity_compartment.dayz_compartment.id
  dns_label      = "pubsubnet"
  vcn_id         = oci_core_vcn.dayz_vcn.id
}

resource "oci_core_internet_gateway" "generated_oci_core_internet_gateway" {
  compartment_id = oci_identity_compartment.dayz_compartment.id
  display_name   = "igw"
  enabled        = "true"
  vcn_id         = oci_core_vcn.dayz_vcn.id
}

resource "oci_core_default_route_table" "generated_oci_core_default_route_table" {
  display_name = "public-routetable"
  route_rules {
    description       = "traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.generated_oci_core_internet_gateway.id
  }
  manage_default_resource_id = oci_core_vcn.dayz_vcn.id.default_route_table_id
}

resource "oci_core_security_list" "sec_list" {
  compartment_id = oci_identity_compartment.dayz_compartment.id
  display_name   = "sec_list"
  ingress_security_rules {
    description = "Allow all communicate"
    protocol    = "all"
    source      = "0.0.0.0/0"
    stateless   = "false"
  }
  vcn_id = oci_core_vcn.dayz_vcn.id
}