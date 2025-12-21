# ========================================
# NETWORK INFRASTRUCTURE FOR USAGE2ADW
# ========================================
# VCN, Subnets e Security Lists para o projeto Usage2ADW
# Baseado no oracle-samples/usage-reports-to-adw requirements

# ========================================
# VCN MODULE
# ========================================
module "vcn" {
  source                       = "oracle-terraform-modules/vcn/oci"
  version                      = "3.6.0"
  compartment_id               = var.compartment_ocid
  region                       = var.region
  internet_gateway_route_rules = null
  local_peering_gateways       = null
  nat_gateway_route_rules      = null
  vcn_name                     = "usage2adw-vcn"
  vcn_dns_label                = "usage2adw"
  vcn_cidrs                    = ["192.168.0.0/16"]

  # Tags para rastreamento
  defined_tags = var.service_tags.definedTags
  freeform_tags = merge(var.service_tags.freeformTags, {
    Name        = "usage2adw-vcn"
    Purpose     = "Usage2ADW Infrastructure"
    Environment = "Production"
  })
}

# ========================================
# DHCP OPTIONS
# ========================================
resource "oci_core_dhcp_options" "usage2adw_dhcp_options" {
  compartment_id = var.compartment_ocid
  vcn_id         = module.vcn.vcn_id
  display_name   = "usage2adw-dhcp-options"

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  defined_tags  = var.service_tags.definedTags
  freeform_tags = var.service_tags.freeformTags
}

# ========================================
# PRIVATE SUBNET (para VM e ADW Private Endpoint)
# ========================================
resource "oci_core_subnet" "usage2adw_private_subnet" {
  compartment_id             = var.compartment_ocid
  dhcp_options_id            = oci_core_dhcp_options.usage2adw_dhcp_options.id
  vcn_id                     = module.vcn.vcn_id
  cidr_block                 = "192.168.1.0/24"
  display_name               = "usage2adw-private-subnet"
  prohibit_public_ip_on_vnic = true
  security_list_ids          = [oci_core_security_list.usage2adw_private_sl.id]

  defined_tags  = var.service_tags.definedTags
  freeform_tags = var.service_tags.freeformTags
}

# ========================================
# PUBLIC SUBNET (para Load Balancer se necessário)
# ========================================
resource "oci_core_subnet" "usage2adw_public_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "192.168.2.0/24"
  display_name      = "usage2adw-public-subnet"
  security_list_ids = [oci_core_security_list.usage2adw_public_sl.id]

  defined_tags  = var.service_tags.definedTags
  freeform_tags = var.service_tags.freeformTags
}

# ========================================
# SECURITY LIST - PRIVATE SUBNET
# ========================================
resource "oci_core_security_list" "usage2adw_private_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = module.vcn.vcn_id
  display_name   = "usage2adw-private-security-list"

  # Egress Rules - Allow outbound traffic
  egress_security_rules {
    description      = "Allow all outbound traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  # Ingress Rules - Allow SSH access
  ingress_security_rules {
    description = "Allow SSH access"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress Rules - Allow ADW Private Endpoint communication
  ingress_security_rules {
    description = "Allow ADW Private Endpoint - Port 1522"
    source      = "192.168.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 1522
      max = 1522
    }
  }

  # Ingress Rules - Allow HTTPS for ADW
  ingress_security_rules {
    description = "Allow HTTPS for ADW"
    source      = "192.168.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Ingress Rules - Allow internal communication
  ingress_security_rules {
    description = "Allow internal VCN communication"
    source      = "192.168.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "all"
    stateless   = false
  }

  defined_tags  = var.service_tags.definedTags
  freeform_tags = var.service_tags.freeformTags
}

# ========================================
# SECURITY LIST - PUBLIC SUBNET
# ========================================
resource "oci_core_security_list" "usage2adw_public_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = module.vcn.vcn_id
  display_name   = "usage2adw-public-security-list"

  # Egress Rules - Allow all outbound traffic
  egress_security_rules {
    description      = "Allow all outbound traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  # Ingress Rules - Allow HTTP
  ingress_security_rules {
    description = "Allow HTTP traffic"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Ingress Rules - Allow HTTPS
  ingress_security_rules {
    description = "Allow HTTPS traffic"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 443
      max = 443
    }
  }

  defined_tags  = var.service_tags.definedTags
  freeform_tags = var.service_tags.freeformTags
}

# ========================================
# OUTPUTS
# ========================================
output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.vcn.vcn_id
}

output "private_subnet_id" {
  description = "OCID of the private subnet"
  value       = oci_core_subnet.usage2adw_private_subnet.id
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.usage2adw_public_subnet.id
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  value       = module.vcn.internet_gateway_id
}

output "nat_gateway_id" {
  description = "OCID of the NAT Gateway"
  value       = module.vcn.nat_gateway_id
}

output "service_gateway_id" {
  description = "OCID of the Service Gateway"
  value       = module.vcn.service_gateway_id
}