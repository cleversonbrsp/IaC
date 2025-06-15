resource "oci_core_vcn" "dayz_vcn" {
  compartment_id = oci_identity_compartment.dayz_compartment.id
  display_name   = "dayz-vcn"
  cidr_block     = "192.168.0.0/16"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = oci_identity_compartment.dayz_compartment.id
  display_name   = "igw"
  enabled        = true
  vcn_id         = oci_core_vcn.dayz_vcn.id
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = oci_identity_compartment.dayz_compartment.id
  vcn_id         = oci_core_vcn.dayz_vcn.id
  display_name   = "public-routetable"

  route_rules {
    description       = "Send all traffic to Internet Gateway"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "sec_list" {
  compartment_id = oci_identity_compartment.dayz_compartment.id
  vcn_id         = oci_core_vcn.dayz_vcn.id
  display_name   = "sec_list"

  ingress_security_rules {
    protocol    = "all"
    source      = "0.0.0.0/0"
    description = "Allow all inbound traffic"
    stateless   = false
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Allow all outbound traffic"
    stateless   = false
  }
}

resource "oci_core_subnet" "pub_subnet" {
  compartment_id      = oci_identity_compartment.dayz_compartment.id
  display_name        = "pub_subnet"
  cidr_block          = "192.168.1.0/24"
  vcn_id              = oci_core_vcn.dayz_vcn.id
  route_table_id      = oci_core_route_table.public_rt.id
  security_list_ids   = [oci_core_security_list.sec_list.id]
  prohibit_public_ip_on_vnic = false
}
