resource "oci_core_vcn" "dayz_vcn" {
  compartment_id = var.comp_id
  display_name   = "dayz-vcn"
  cidr_block     = "192.168.0.0/16"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.comp_id
  display_name   = "igw"
  enabled        = true
  vcn_id         = oci_core_vcn.dayz_vcn.id
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.comp_id
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
  compartment_id = var.comp_id
  vcn_id         = oci_core_vcn.dayz_vcn.id
  display_name   = "dayz-security-list"

  # SSH
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "Allow SSH"
    stateless   = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  # DayZ Server - Porta principal (2302 TCP/UDP)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "DayZ Server TCP"
    stateless   = false

    tcp_options {
      min = 2302
      max = 2302
    }
  }

  ingress_security_rules {
    protocol    = "17" # UDP
    source      = "0.0.0.0/0"
    description = "DayZ Server UDP"
    stateless   = false

    udp_options {
      min = 2302
      max = 2302
    }
  }

  # DayZ Server - Portas adicionais (2303-2305 UDP)
  ingress_security_rules {
    protocol    = "17" # UDP
    source      = "0.0.0.0/0"
    description = "DayZ Server UDP Additional Ports"
    stateless   = false

    udp_options {
      min = 2303
      max = 2305
    }
  }

  # DayZ Server - Porta adicional 2306 UDP
  ingress_security_rules {
    protocol    = "17" # UDP
    source      = "0.0.0.0/0"
    description = "DayZ Server UDP Port 2306"
    stateless   = false

    udp_options {
      min = 2306
      max = 2306
    }
  }

  # Steam - Porta de query (27016 UDP)
  ingress_security_rules {
    protocol    = "17" # UDP
    source      = "0.0.0.0/0"
    description = "Steam Query Port"
    stateless   = false

    udp_options {
      min = 27016
      max = 27016
    }
  }

  # ICMP para troubleshooting
  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "0.0.0.0/0"
    description = "Allow ICMP"
    stateless   = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "10.0.0.0/16"
    description = "Allow ICMP from VCN"
    stateless   = false

    icmp_options {
      type = 3
    }
  }

  # ⚠️ REGRA TEMPORÁRIA PARA TESTES - REMOVER EM PRODUÇÃO ⚠️
  # Permite TODO o tráfego de entrada (apenas para testes)
  # ingress_security_rules {
  #   protocol         = "all"
  #   source           = "0.0.0.0/0"
  #   description      = "⚠️ TEMPORÁRIO: Allow all inbound traffic (REMOVER EM PRODUÇÃO)"
  #   stateless        = false
  #   source_type      = "CIDR_BLOCK"
  # }

  # Egress - Allow all outbound traffic
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    description      = "Allow all outbound traffic"
    stateless        = false
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "pub_subnet" {
  compartment_id      = var.comp_id
  display_name        = "pub_subnet"
  cidr_block          = "192.168.1.0/24"
  vcn_id              = oci_core_vcn.dayz_vcn.id
  route_table_id      = oci_core_route_table.public_rt.id
  security_list_ids   = [oci_core_security_list.sec_list.id]
  prohibit_public_ip_on_vnic = false
}
