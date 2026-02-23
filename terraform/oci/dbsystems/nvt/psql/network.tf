# =============================================================================
# Unified network: VCN, gateways, subnets, security lists and NSGs
# =============================================================================
# - Single VCN for the lab (PostgreSQL + OpenVPN in the same VCN).
# - DB subnet: private, no public IP; PostgreSQL and SSH accessible from entire VCN.
# - VPN subnet: route to IGW (public IP on VNIC); OpenVPN UDP + SSH from internet.
# =============================================================================

# -----------------------------------------------------------------------------
# VCN
# -----------------------------------------------------------------------------
resource "oci_core_vcn" "postgresql_vcn" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = local.compartment_id
  display_name   = var.vcn_display_name
  dns_label      = var.vcn_dns_label
  defined_tags   = var.common_tags.defined_tags

  depends_on = [time_sleep.wait_compartment_propagation]
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
# Required for the OpenVPN instance public IP to be reachable from the internet.
resource "oci_core_internet_gateway" "igw" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgresql_vcn.id
  display_name   = "postgresql-vcn-igw"
  enabled        = true
  defined_tags   = var.common_tags.defined_tags
}

# =============================================================================
# PostgreSQL (DB) subnet — private
# =============================================================================
# prohibit_public_ip_on_vnic = true. DB access via VPN (VPN subnet in same VCN).

resource "oci_core_subnet" "postgresql_subnet" {
  cidr_block                 = var.subnet_cidr_block
  compartment_id             = local.compartment_id
  display_name               = var.subnet_display_name
  dns_label                  = var.subnet_dns_label
  prohibit_public_ip_on_vnic = true
  vcn_id                     = oci_core_vcn.postgresql_vcn.id
  defined_tags               = var.common_tags.defined_tags
  security_list_ids          = [oci_core_security_list.postgresql_sec_list.id]
}

# Security list for DB subnet: 5432 and 22 from entire VCN (includes VPN subnet for OpenVPN access).
resource "oci_core_security_list" "postgresql_sec_list" {
  compartment_id = local.compartment_id
  display_name   = "${var.subnet_display_name}-seclist"
  vcn_id         = oci_core_vcn.postgresql_vcn.id
  defined_tags   = var.common_tags.defined_tags

  egress_security_rules {
    description      = "Allow all outbound"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }
  ingress_security_rules {
    description = "PostgreSQL 5432 from VCN (includes VPN subnet)"
    protocol    = "6"
    source      = var.vcn_cidr_block
    stateless   = false
    tcp_options {
      min = 5432
      max = 5432
    }
  }
  ingress_security_rules {
    description = "SSH 22 from VCN"
    protocol    = "6"
    source      = var.vcn_cidr_block
    stateless   = false
    tcp_options {
      min = 22
      max = 22
    }
  }
}

# NSG for the DB system (PostgreSQL).
resource "oci_core_network_security_group" "postgresql_nsg" {
  compartment_id = local.compartment_id
  display_name   = var.nsg_display_name
  vcn_id         = oci_core_vcn.postgresql_vcn.id
  defined_tags   = var.common_tags.defined_tags
}

resource "oci_core_network_security_group_security_rule" "postgresql_nsg_ingress" {
  network_security_group_id = oci_core_network_security_group.postgresql_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vcn_cidr_block
  source_type               = "CIDR_BLOCK"
  description               = "PostgreSQL 5432 from VCN"
  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

resource "oci_core_network_security_group_security_rule" "postgresql_nsg_egress" {
  network_security_group_id = oci_core_network_security_group.postgresql_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Allow all outbound"
}

# =============================================================================
# VPN subnet (OpenVPN) — public IP on VNIC
# =============================================================================
# Route table: default to IGW for internet traffic. prohibit_public_ip_on_vnic = false.

resource "oci_core_route_table" "vpn_route_table" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgresql_vcn.id
  display_name   = "ovpn-route-table"
  defined_tags   = var.common_tags.defined_tags

  route_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
    description      = "Default route to Internet Gateway"
  }
}

resource "oci_core_subnet" "vpn_subnet" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.postgresql_vcn.id
  cidr_block                 = var.vpn_subnet_cidr
  display_name               = "ovpn-subnet"
  dns_label                  = "ovpnsubnet"
  prohibit_public_ip_on_vnic = false
  defined_tags               = var.common_tags.defined_tags
  security_list_ids          = [oci_core_security_list.vpn_sec_list.id]
  route_table_id             = oci_core_route_table.vpn_route_table.id
}

# Security list for VPN subnet: SSH from internet + SSH/5432 from internal subnets.
resource "oci_core_security_list" "vpn_sec_list" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgresql_vcn.id
  display_name   = "ovpn-seclist"
  defined_tags   = var.common_tags.defined_tags

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }
  ingress_security_rules {
    description = "SSH from allowed CIDR (internet)"
    protocol    = "6"
    source      = var.ssh_allowed_cidr
    stateless   = false
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    description = "SSH from VPN subnet"
    protocol    = "6"
    source      = var.vpn_subnet_cidr
    stateless   = false
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    description = "PostgreSQL 5432 from DB subnet"
    protocol    = "6"
    source      = var.db_subnet_cidr
    stateless   = false
    tcp_options {
      min = 5432
      max = 5432
    }
  }
}

# NSG for the OpenVPN instance (additional rules; OpenVPN UDP is only in NSG).
resource "oci_core_network_security_group" "vpn_nsg" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.postgresql_vcn.id
  display_name   = "ovpn-nsg"
  defined_tags   = var.common_tags.defined_tags
}

resource "oci_core_network_security_group_security_rule" "vpn_udp" {
  network_security_group_id = oci_core_network_security_group.vpn_nsg.id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "OpenVPN UDP"
  udp_options {
    destination_port_range {
      min = var.openvpn_port
      max = var.openvpn_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "vpn_ssh" {
  network_security_group_id = oci_core_network_security_group.vpn_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.ssh_allowed_cidr
  source_type               = "CIDR_BLOCK"
  description               = "SSH"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "vpn_egress" {
  network_security_group_id = oci_core_network_security_group.vpn_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Allow all outbound"
}
