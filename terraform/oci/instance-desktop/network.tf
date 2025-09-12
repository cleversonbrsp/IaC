# VCN
resource "oci_core_vcn" "lab_vcn" {
  compartment_id = oci_identity_compartment.crodrigues.id
  cidr_block     = var.vcn_cidr
  display_name   = "vcn-instances"
}

# Security List com regras mínimas necessárias
resource "oci_core_security_list" "sec_list" {
  compartment_id = oci_identity_compartment.crodrigues.id
  display_name   = "sec_list"  

  # Ingress: SSH e RDP de casa
  ingress_security_rules {
    description = "Allow SSH from home"
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
    stateless = false
  }

  ingress_security_rules {
    description = "Allow RDP from home"
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    tcp_options {
      min = 3389
      max = 3389
    }
    stateless = false
  }

  # Egress: todo tráfego para internet
  egress_security_rules {
    description     = "Allow all outbound"
    protocol        = "all"
    destination     = "0.0.0.0/0"
    stateless       = false
  }

  vcn_id = oci_core_vcn.lab_vcn.id
}

# Subnet pública associando a security list
resource "oci_core_subnet" "pub_subnet" {
  cidr_block        = var.subnet_cidr
  display_name      = "pub_subnet"
  compartment_id    = oci_identity_compartment.crodrigues.id
  vcn_id            = oci_core_vcn.lab_vcn.id
  security_list_ids = [oci_core_security_list.sec_list.id]
}

# Internet Gateway
resource "oci_core_internet_gateway" "igw" {
  compartment_id = oci_identity_compartment.crodrigues.id
  display_name   = "igw"
  enabled        = true
  vcn_id         = oci_core_vcn.lab_vcn.id
}

# Route Table padrão para tráfego internet
resource "oci_core_default_route_table" "default_rt" {
  display_name = "public-routetable"
  route_rules {
    description       = "Traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }

  manage_default_resource_id = oci_core_vcn.lab_vcn.default_route_table_id
}
