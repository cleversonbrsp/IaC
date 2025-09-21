# VCN - Virtual Cloud Network
resource "oci_core_vcn" "postgres_vcn" {
  compartment_id = local.compartment_id
  display_name   = local.vcn_display_name
  dns_label      = local.vcn_dns_label
  cidr_blocks    = [var.vcn_cidr_block]

  freeform_tags = local.common_tags
}

# Internet Gateway
resource "oci_core_internet_gateway" "postgres_ig" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgres_vcn.id
  display_name   = "${local.name_prefix}-ig"
  enabled        = true

  freeform_tags = local.common_tags
}

# NAT Gateway
resource "oci_core_nat_gateway" "postgres_nat" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgres_vcn.id
  display_name   = "${local.name_prefix}-nat"

  freeform_tags = local.common_tags
}

# Service Gateway
data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "postgres_sg" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgres_vcn.id
  display_name   = "${local.name_prefix}-sg"

  services {
    service_id = data.oci_core_services.all_oci_services.services[0].id
  }

  freeform_tags = local.common_tags
}

# Route Tables
resource "oci_core_route_table" "postgres_public_rt" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgres_vcn.id
  display_name   = "${local.name_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.postgres_ig.id
  }

  freeform_tags = local.common_tags
}

resource "oci_core_route_table" "postgres_private_rt" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgres_vcn.id
  display_name   = "${local.name_prefix}-private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.postgres_nat.id
  }

  route_rules {
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.postgres_sg.id
  }

  freeform_tags = local.common_tags
}

# Security Lists
resource "oci_core_security_list" "postgres_private_sl" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgres_vcn.id
  display_name   = local.private_security_list_name

  # Egress Rules
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
    description = "Allow all outbound traffic"
  }

  # Ingress Rules
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow PostgreSQL access from public subnet"

    tcp_options {
      min = 5432
      max = 5432
    }
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.private_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow internal communication within private subnet"
  }

  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = var.vcn_cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow ICMP from VCN"

    icmp_options {
      type = 3
      code = 4
    }
  }

  freeform_tags = local.common_tags
}

resource "oci_core_security_list" "postgres_public_sl" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgres_vcn.id
  display_name   = local.public_security_list_name

  # Egress Rules
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
    description = "Allow all outbound traffic"
  }

  # Ingress Rules
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow SSH access"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow ICMP"

    icmp_options {
      type = 3
      code = 4
    }
  }

  freeform_tags = local.common_tags
}

# Network Security Group for PostgreSQL
resource "oci_core_network_security_group" "postgres_nsg" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgres_vcn.id
  display_name   = local.nsg_name

  freeform_tags = local.common_tags
}

# NSG Rules for PostgreSQL
resource "oci_core_network_security_group_security_rule" "postgres_nsg_ingress_5432" {
  network_security_group_id = oci_core_network_security_group.postgres_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  description = "Allow PostgreSQL access"
  source      = var.vcn_cidr_block
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

resource "oci_core_network_security_group_security_rule" "postgres_nsg_egress_all" {
  network_security_group_id = oci_core_network_security_group.postgres_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"

  description      = "Allow all outbound traffic"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  stateless        = false
}

# Subnets
resource "oci_core_subnet" "postgres_private_subnet" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.postgres_vcn.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = local.private_subnet_name
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.postgres_private_rt.id
  security_list_ids          = [oci_core_security_list.postgres_private_sl.id]

  freeform_tags = local.common_tags
}

resource "oci_core_subnet" "postgres_public_subnet" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.postgres_vcn.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = local.public_subnet_name
  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.postgres_public_rt.id
  security_list_ids          = [oci_core_security_list.postgres_public_sl.id]

  freeform_tags = local.common_tags
}