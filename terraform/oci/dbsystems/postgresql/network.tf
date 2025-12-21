# VCN Resource (created only if create_network_resources is true)
resource "oci_core_vcn" "postgresql_vcn" {
  count          = var.create_network_resources ? 1 : 0
  cidr_block     = var.vcn_cidr_block
  compartment_id = coalesce(var.comp_id, var.compartment_id)
  display_name   = var.vcn_display_name
  dns_label      = var.vcn_dns_label
  defined_tags   = var.common_tags.defined_tags
}

# Internet Gateway (optional, for public subnets)
resource "oci_core_internet_gateway" "postgresql_igw" {
  count          = var.create_network_resources && !var.subnet_prohibit_public_ip ? 1 : 0
  compartment_id = coalesce(var.comp_id, var.compartment_id)
  display_name   = "${var.vcn_display_name}-igw"
  enabled        = "true"
  vcn_id         = oci_core_vcn.postgresql_vcn[0].id
  defined_tags   = var.common_tags.defined_tags
}

# Default Route Table (updated only if IGW is created)
resource "oci_core_default_route_table" "postgresql_default_route_table" {
  count                      = var.create_network_resources && !var.subnet_prohibit_public_ip ? 1 : 0
  display_name               = "default"
  manage_default_resource_id = oci_core_vcn.postgresql_vcn[0].default_route_table_id
  defined_tags               = var.common_tags.defined_tags

  route_rules {
    description       = "traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.postgresql_igw[0].id
  }
}

# Subnet Resource (created only if create_network_resources is true)
resource "oci_core_subnet" "postgresql_subnet" {
  count                      = var.create_network_resources ? 1 : 0
  cidr_block                 = var.subnet_cidr_block
  compartment_id             = coalesce(var.comp_id, var.compartment_id)
  display_name               = var.subnet_display_name
  dns_label                  = var.subnet_dns_label
  prohibit_public_ip_on_vnic = var.subnet_prohibit_public_ip ? "true" : "false"
  vcn_id                     = oci_core_vcn.postgresql_vcn[0].id
  defined_tags               = var.common_tags.defined_tags

  route_table_id = var.subnet_prohibit_public_ip ? null : oci_core_default_route_table.postgresql_default_route_table[0].id

  security_list_ids = var.create_network_resources ? [oci_core_security_list.postgresql_sec_list[0].id] : []
}

# Security List for PostgreSQL Subnet
resource "oci_core_security_list" "postgresql_sec_list" {
  count          = var.create_network_resources ? 1 : 0
  compartment_id = coalesce(var.comp_id, var.compartment_id)
  display_name   = "${var.subnet_display_name}-seclist"
  vcn_id         = oci_core_vcn.postgresql_vcn[0].id
  defined_tags   = var.common_tags.defined_tags

  # Egress rules - allow outbound traffic
  egress_security_rules {
    description      = "Allow all outbound traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }

  # Ingress rules - PostgreSQL default port 5432
  ingress_security_rules {
    description = "PostgreSQL database access from VCN"
    protocol    = "6" # TCP
    source      = var.vcn_cidr_block
    stateless   = "false"

    tcp_options {
      min = 5432
      max = 5432
    }
  }

  # Allow SSH access (optional, adjust as needed)
  ingress_security_rules {
    description = "SSH access"
    protocol    = "6" # TCP
    source      = var.vcn_cidr_block
    stateless   = "false"

    tcp_options {
      min = 22
      max = 22
    }
  }
}

# Network Security Group for PostgreSQL
resource "oci_core_network_security_group" "postgresql_nsg" {
  count          = var.create_network_resources ? 1 : 0
  compartment_id = coalesce(var.comp_id, var.compartment_id)
  display_name   = var.nsg_display_name
  vcn_id         = oci_core_vcn.postgresql_vcn[0].id
  defined_tags   = var.common_tags.defined_tags
}

# NSG Rules - PostgreSQL access
resource "oci_core_network_security_group_security_rule" "postgresql_nsg_ingress" {
  count                     = var.create_network_resources ? 1 : 0
  network_security_group_id = oci_core_network_security_group.postgresql_nsg[0].id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = var.vcn_cidr_block
  source_type               = "CIDR_BLOCK"
  description               = "PostgreSQL database access from VCN"

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

# NSG Rules - Egress
resource "oci_core_network_security_group_security_rule" "postgresql_nsg_egress" {
  count                     = var.create_network_resources ? 1 : 0
  network_security_group_id = oci_core_network_security_group.postgresql_nsg[0].id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination                = "0.0.0.0/0"
  destination_type           = "CIDR_BLOCK"
  description                = "Allow all outbound traffic"
}

