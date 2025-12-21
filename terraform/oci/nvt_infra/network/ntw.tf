# ========================================
# VCN
# ========================================
resource "oci_core_vcn" "nvt_infra_vcn" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = local.compartment_id
  display_name   = var.vcn_display_name
  dns_label      = var.vcn_dns_label
  defined_tags   = local.defined_tags
}

# ========================================
# Internet Gateway
# ========================================
resource "oci_core_internet_gateway" "nvt_infra_igw" {
  compartment_id = local.compartment_id
  display_name   = "nvt-infra-igw"
  enabled        = "true"
  vcn_id         = oci_core_vcn.nvt_infra_vcn.id
  defined_tags   = local.defined_tags
}

# ========================================
# NAT Gateway (for private subnets to access internet)
# ========================================
resource "oci_core_nat_gateway" "nvt_infra_nat_gw" {
  compartment_id = local.compartment_id
  display_name   = "nvt-infra-nat-gw"
  vcn_id         = oci_core_vcn.nvt_infra_vcn.id
  defined_tags   = local.defined_tags
}

# ========================================
# Service Gateway (for OCI Services access)
# ========================================
data "oci_core_services" "oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "nvt_infra_sg" {
  compartment_id = local.compartment_id
  display_name   = "nvt-infra-service-gw"
  vcn_id         = oci_core_vcn.nvt_infra_vcn.id
  services {
    service_id = data.oci_core_services.oci_services.services[0].id
  }
  defined_tags = local.defined_tags
}

# ========================================
# Route Tables
# ========================================

# Default Route Table (for public subnets)
resource "oci_core_default_route_table" "public_route_table" {
  display_name = "nvt-infra-public-rt"
  route_rules {
    description       = "traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.nvt_infra_igw.id
  }
  manage_default_resource_id = oci_core_vcn.nvt_infra_vcn.default_route_table_id
  defined_tags               = local.defined_tags
}

# Private Route Table (for private subnets)
resource "oci_core_route_table" "private_route_table" {
  compartment_id = local.compartment_id
  display_name   = "nvt-infra-private-rt"
  vcn_id         = oci_core_vcn.nvt_infra_vcn.id
  route_rules {
    description       = "traffic to internet via NAT Gateway"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nvt_infra_nat_gw.id
  }
  route_rules {
    description       = "traffic to OCI services via Service Gateway"
    destination       = data.oci_core_services.oci_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.nvt_infra_sg.id
  }
  defined_tags = local.defined_tags
}

# ========================================
# Security Lists
# ========================================

# OKE API Endpoint Security List
resource "oci_core_security_list" "oke_api_endpoint_sec_list" {
  compartment_id = local.compartment_id
  display_name   = "nvt-oke-api-endpoint-secl"
  vcn_id         = oci_core_vcn.nvt_infra_vcn.id
  defined_tags   = local.defined_tags

  egress_security_rules {
    description      = "Allow Kubernetes Control Plane to communicate with OKE"
    destination      = "all-gru-services-in-oracle-services-network"
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "All traffic to worker nodes"
    destination      = var.oke_node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Path discovery to worker nodes"
    destination      = var.oke_node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  ingress_security_rules {
    description = "External access to Kubernetes API endpoint"
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Kubernetes worker to Kubernetes API endpoint communication"
    protocol    = "6"
    source      = var.oke_node_subnet_cidr
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Path discovery from worker nodes"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    source    = var.oke_node_subnet_cidr
    stateless = "false"
  }
}

# OKE Node Subnet Security List
resource "oci_core_security_list" "oke_node_sec_list" {
  compartment_id = local.compartment_id
  display_name   = "nvt-oke-node-secl"
  vcn_id         = oci_core_vcn.nvt_infra_vcn.id
  defined_tags   = local.defined_tags

  egress_security_rules {
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
    destination      = var.oke_node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Access to Kubernetes API Endpoint"
    destination      = var.oke_api_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Path discovery to API endpoint"
    destination      = var.oke_api_subnet_cidr
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Allow nodes to communicate with OKE services"
    destination      = "all-gru-services-in-oracle-services-network"
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Worker Nodes access to Internet"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Access to database subnet"
    destination      = var.db_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
    tcp_options {
      min = 5432
      max = 5432
    }
  }
  ingress_security_rules {
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
    protocol    = "all"
    source      = var.oke_node_subnet_cidr
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Path discovery from API endpoint"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    source    = var.oke_api_subnet_cidr
    stateless = "false"
  }
  ingress_security_rules {
    description = "TCP access from Kubernetes Control Plane"
    protocol    = "6"
    source      = var.oke_api_subnet_cidr
    stateless   = "false"
  }
  ingress_security_rules {
    description = "SSH access from VPN subnet"
    protocol    = "6"
    source      = var.vpn_subnet_cidr
    stateless   = "false"
    tcp_options {
      min = 22
      max = 22
    }
  }
}

# OKE Load Balancer Security List
resource "oci_core_security_list" "oke_lb_sec_list" {
  compartment_id = local.compartment_id
  display_name   = "nvt-oke-lb-secl"
  vcn_id         = oci_core_vcn.nvt_infra_vcn.id
  defined_tags   = local.defined_tags

  egress_security_rules {
    description      = "Allow load balancer to reach worker nodes"
    destination      = var.oke_node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  ingress_security_rules {
    description = "Allow HTTP traffic from internet"
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = "false"
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    description = "Allow HTTPS traffic from internet"
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = "false"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

# VPN Subnet Security List
resource "oci_core_security_list" "vpn_sec_list" {
  compartment_id = local.compartment_id
  display_name   = "nvt-vpn-secl"
  vcn_id         = oci_core_vcn.nvt_infra_vcn.id
  defined_tags   = local.defined_tags

  egress_security_rules {
    description      = "Allow all outbound traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  ingress_security_rules {
    description = "Allow OpenVPN UDP traffic from internet"
    protocol    = "17"
    source      = "0.0.0.0/0"
    stateless   = "false"
    udp_options {
      min = 1194
      max = 1194
    }
  }
  ingress_security_rules {
    description = "Allow OpenVPN TCP traffic from internet"
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = "false"
    tcp_options {
      min = 1194
      max = 1194
    }
  }
  ingress_security_rules {
    description = "Allow SSH access from internet"
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = "false"
    tcp_options {
      min = 22
      max = 22
    }
  }
}

# Database Subnet Security List (Private - no public access)
resource "oci_core_security_list" "db_sec_list" {
  compartment_id = local.compartment_id
  display_name   = "nvt-db-secl"
  vcn_id         = oci_core_vcn.nvt_infra_vcn.id
  defined_tags   = local.defined_tags

  egress_security_rules {
    description      = "Allow database to initiate connections to OCI services"
    destination      = "all-gru-services-in-oracle-services-network"
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Allow database to respond to VPN subnet"
    destination      = var.vpn_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Allow database to respond to OKE node subnet"
    destination      = var.oke_node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
  }
  ingress_security_rules {
    description = "Allow PostgreSQL access from VPN subnet"
    protocol    = "6"
    source      = var.vpn_subnet_cidr
    stateless   = "false"
    tcp_options {
      min = 5432
      max = 5432
    }
  }
  ingress_security_rules {
    description = "Allow PostgreSQL access from OKE node subnet"
    protocol    = "6"
    source      = var.oke_node_subnet_cidr
    stateless   = "false"
    tcp_options {
      min = 5432
      max = 5432
    }
  }
  ingress_security_rules {
    description = "Allow SSH access from VPN subnet for administration"
    protocol    = "6"
    source      = var.vpn_subnet_cidr
    stateless   = "false"
    tcp_options {
      min = 22
      max = 22
    }
  }
}

# ========================================
# Subnets
# ========================================

# OKE API Endpoint Subnet (Public)
resource "oci_core_subnet" "oke_api_endpoint_subnet" {
  cidr_block                 = var.oke_api_subnet_cidr
  compartment_id             = local.compartment_id
  display_name               = "nvt-oke-api-endpoint-subnet"
  dns_label                  = "okeapiendpoint"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_default_route_table.public_route_table.id
  security_list_ids          = [oci_core_security_list.oke_api_endpoint_sec_list.id]
  vcn_id                     = oci_core_vcn.nvt_infra_vcn.id
  defined_tags               = local.defined_tags
}

# OKE Node Subnet (Public)
resource "oci_core_subnet" "oke_node_subnet" {
  cidr_block                 = var.oke_node_subnet_cidr
  compartment_id             = local.compartment_id
  display_name               = "nvt-oke-node-subnet"
  dns_label                  = "okenodes"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_default_route_table.public_route_table.id
  security_list_ids          = [oci_core_security_list.oke_node_sec_list.id]
  vcn_id                     = oci_core_vcn.nvt_infra_vcn.id
  defined_tags               = local.defined_tags
}

# OKE Load Balancer Subnet (Public)
resource "oci_core_subnet" "oke_lb_subnet" {
  cidr_block                 = var.oke_lb_subnet_cidr
  compartment_id             = local.compartment_id
  display_name               = "nvt-oke-lb-subnet"
  dns_label                  = "okelb"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_default_route_table.public_route_table.id
  security_list_ids          = [oci_core_security_list.oke_lb_sec_list.id]
  vcn_id                     = oci_core_vcn.nvt_infra_vcn.id
  defined_tags               = local.defined_tags
}

# VPN Subnet (Public - needs public IP for OpenVPN access)
resource "oci_core_subnet" "vpn_subnet" {
  cidr_block                 = var.vpn_subnet_cidr
  compartment_id             = local.compartment_id
  display_name               = "nvt-vpn-subnet"
  dns_label                  = "vpnsubnet"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_default_route_table.public_route_table.id
  security_list_ids          = [oci_core_security_list.vpn_sec_list.id]
  vcn_id                     = oci_core_vcn.nvt_infra_vcn.id
  defined_tags               = local.defined_tags
}

# Database Subnet (Private)
resource "oci_core_subnet" "db_subnet" {
  cidr_block                 = var.db_subnet_cidr
  compartment_id             = local.compartment_id
  display_name               = "nvt-db-subnet"
  dns_label                  = "dbsubnet"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.private_route_table.id
  security_list_ids          = [oci_core_security_list.db_sec_list.id]
  vcn_id                     = oci_core_vcn.nvt_infra_vcn.id
  defined_tags               = local.defined_tags
}

