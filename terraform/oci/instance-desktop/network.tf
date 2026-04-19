# --- VCN e gateways (IGW = subnet VPN; NAT + SGW = subnet privada) ---

resource "oci_core_vcn" "vcn" {
  compartment_id = local.compartment_id
  cidr_blocks    = [var.vcn_cidr]

  display_name = var.vcn_display_name
  dns_label    = var.vcn_dns_label

  defined_tags = var.common_tags.defined_tags

  depends_on = [time_sleep.after_compartment]
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = local.compartment_id
  display_name   = "${var.vcn_display_name}-igw"
  enabled        = true
  vcn_id         = oci_core_vcn.vcn.id

  defined_tags = var.common_tags.defined_tags
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = local.compartment_id
  display_name   = "${var.vcn_display_name}-nat"
  vcn_id         = oci_core_vcn.vcn.id

  defined_tags = var.common_tags.defined_tags
}

resource "oci_core_service_gateway" "sgw" {
  compartment_id = local.compartment_id
  display_name   = "${var.vcn_display_name}-sgw"
  vcn_id         = oci_core_vcn.vcn.id

  services {
    service_id = local.oracle_services_network.id
  }

  defined_tags = var.common_tags.defined_tags
}

# --- Route tables ---

resource "oci_core_route_table" "vpn_public" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_display_name}-vpn-public-igw"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }

  defined_tags = var.common_tags.defined_tags
}

# Egresso: internet via NAT; tráfego para a Oracle Services Network via SGW.
resource "oci_core_route_table" "private_egress" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_display_name}-private-nat-sgw"

  route_rules {
    destination       = local.oracle_services_network.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw.id
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat.id
  }

  defined_tags = var.common_tags.defined_tags
}

# --- Subnet VPN (pública) + SL ---

resource "oci_core_security_list" "vpn_sl" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_display_name}-vpn-sl"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "17"
    source   = var.openvpn_udp_ingress_cidr
    udp_options {
      min = var.openvpn_port
      max = var.openvpn_port
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.vpn_ssh_ingress_cidr
    tcp_options {
      min = 22
      max = 22
    }
  }

  defined_tags = var.common_tags.defined_tags
}

resource "oci_core_subnet" "vpn" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  cidr_block     = var.vpn_subnet_cidr
  display_name   = "${var.vcn_display_name}-vpn-subnet"
  dns_label      = "vpn"

  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.vpn_public.id
  security_list_ids          = [oci_core_security_list.vpn_sl.id]

  defined_tags = var.common_tags.defined_tags
}

# --- NSG + SL da subnet privada (desktop) ---

resource "oci_core_network_security_group" "desktop_nsg" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_display_name}-nsg"

  defined_tags = var.common_tags.defined_tags
}

resource "oci_core_network_security_group_security_rule" "desktop_nsg_ingress_ssh_vpn_subnet" {
  network_security_group_id = oci_core_network_security_group.desktop_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vpn_subnet_cidr

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "desktop_nsg_ingress_ssh_ovpn_clients" {
  network_security_group_id = oci_core_network_security_group.desktop_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.openvpn_client_cidr

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "desktop_nsg_ingress_rdp_vpn_subnet" {
  network_security_group_id = oci_core_network_security_group.desktop_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vpn_subnet_cidr

  tcp_options {
    destination_port_range {
      min = 3389
      max = 3389
    }
  }
}

resource "oci_core_network_security_group_security_rule" "desktop_nsg_ingress_rdp_ovpn_clients" {
  network_security_group_id = oci_core_network_security_group.desktop_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.openvpn_client_cidr

  tcp_options {
    destination_port_range {
      min = 3389
      max = 3389
    }
  }
}

resource "oci_core_network_security_group_security_rule" "desktop_nsg_ingress_ssh_extra" {
  for_each = toset(var.extra_admin_cidrs)

  network_security_group_id = oci_core_network_security_group.desktop_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "desktop_nsg_ingress_rdp_extra" {
  for_each = toset(var.extra_admin_cidrs)

  network_security_group_id = oci_core_network_security_group.desktop_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value

  tcp_options {
    destination_port_range {
      min = 3389
      max = 3389
    }
  }
}

resource "oci_core_network_security_group_security_rule" "desktop_nsg_egress_all" {
  network_security_group_id = oci_core_network_security_group.desktop_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
}

resource "oci_core_security_list" "private_sl" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.vcn_display_name}-private-sl"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.vpn_subnet_cidr
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.openvpn_client_cidr
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.vpn_subnet_cidr
    tcp_options {
      min = 3389
      max = 3389
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.openvpn_client_cidr
    tcp_options {
      min = 3389
      max = 3389
    }
  }

  defined_tags = var.common_tags.defined_tags
}

resource "oci_core_subnet" "private" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  cidr_block     = var.private_subnet_cidr
  display_name   = "${var.vcn_display_name}-private-subnet"
  dns_label      = "priv"

  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private_egress.id
  security_list_ids          = [oci_core_security_list.private_sl.id]

  defined_tags = var.common_tags.defined_tags
}
