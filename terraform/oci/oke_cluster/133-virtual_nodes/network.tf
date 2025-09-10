module "vcn" {
  source                       = "oracle-terraform-modules/vcn/oci"
  version                      = "3.6.0"
  compartment_id               = oci_identity_compartment.crodrigues.id
  region                       = var.oci_region
  internet_gateway_route_rules = null
  local_peering_gateways       = null
  nat_gateway_route_rules      = null
  vcn_name                     = "oke-vcn-virtual-nodes"
  vcn_dns_label                = "okevirtualnodes"
  vcn_cidrs                    = ["10.15.0.0/18"]
}

##### DHCP Options #####
resource "oci_core_dhcp_options" "private-dhcp-options-for-oke-vcn-prod" {
  compartment_id = oci_identity_compartment.crodrigues.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "private-dhcp-options-for-oke-vcn-prod"
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
}

##### Route Tables #####
# Use default route tables from VCN module

##### Private Subnet definitions #####
resource "oci_core_subnet" "vcn_private_subnet" {
  compartment_id             = oci_identity_compartment.crodrigues.id
  dhcp_options_id            = oci_core_dhcp_options.private-dhcp-options-for-oke-vcn-prod.id
  vcn_id                     = module.vcn.vcn_id
  cidr_block                 = "10.15.0.0/20"
  # Use default route table - no custom route table needed
  security_list_ids          = [oci_core_security_list.private_subnet_sl.id]
  display_name               = "virtual-nodes-private-node-subnet"
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_security_list" "private_subnet_sl" {
  compartment_id = oci_identity_compartment.crodrigues.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "virtual-nodes-private-node-subnet-sl"
  egress_security_rules {
    stateless        = false
    description      = "internet"
    destination      = "10.15.0.0/20" #virtual-nodes-private-node-subnet
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  egress_security_rules {
    stateless        = false
    description      = "Kubernetes API Endpoint"
    destination      = "10.15.16.0/20" #virtual-nodes-public-api-subnet-sl
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options { #Kubernetes API Endpoint 
      min = 6443
      max = 6443
    }
  }
  egress_security_rules {
    stateless        = false
    description      = "Kubernetes worker control plane communication"
    destination      = "10.15.16.0/20" #virtual-nodes-public-api-subnet-sl
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options { #Kubernetes worker control plane communication
      min = 12250
      max = 12250
    }
  }
  egress_security_rules {
    stateless        = false
    description      = "Path discovery"
    destination      = "10.15.16.0/20" #virtual-nodes-public-api-subnet-sl
    destination_type = "CIDR_BLOCK"
    protocol         = "1"
    icmp_options { #Path discovery
      type = 3
      code = 4
    }
  }
  # Removed Service CIDR rule - using CIDR blocks instead
  egress_security_rules {
    stateless        = false
    description      = "ICMP Access from Kubernetes Control Plane"
    destination      = "0.0.0.0/0" #ICMP Access from Kubernetes Control Plane
    destination_type = "CIDR_BLOCK"
    protocol         = "1"
    icmp_options { #ICMP Access from Kubernetes Control Plane
      type = 3
      code = 4
    }
  }
  egress_security_rules {
    stateless        = false
    description      = "Worker Nodes Internet access"
    destination      = "0.0.0.0/0" #Worker Nodes Internet access
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  ingress_security_rules {
    stateless   = false
    description = "PODs for one worker node to communicate with pods on others worker nodes"
    source      = "10.15.0.0/20" #virtual-nodes-private-node-subnet
    source_type = "CIDR_BLOCK"
    protocol    = "all" #PODs for one worker node to communicate with pods on others worker nodes
  }
  ingress_security_rules {
    stateless   = false
    description = "Path discovery"
    source      = "10.15.16.0/20" #virtual-nodes-public-api-subnet-sl
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    icmp_options { #Path discovery
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    stateless   = false
    description = "Allow all traffic from CIDR 10.15.16.0/20"
    source      = "10.15.16.0/20" #Allow all traffic from CIDR 10.15.16.0/20
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 1     # Minimum port (replace as needed)
      max = 65535 # Maximum port (replace as needed)
    }
  }
  ingress_security_rules {
    stateless   = false
    description = "Load Balancer to node Ports"
    source      = "10.15.32.0/20" #virtual-nodes-service-lb-subnet - Load balancer
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options { #Load Balancer to node Ports
      min = 30000
      max = 32767
    }
  }
  ingress_security_rules {
    stateless   = false
    description = "KubeProxy Port, to healthcheck"
    source      = "10.15.32.0/20" #virtual-nodes-service-lb-subnet - Load balancer
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options { #KubeProxy Port, to healthcheck
      min = 10256
      max = 10256
    }
  }
}

##### Public Subnet definitions #####
resource "oci_core_subnet" "vcn_public_subnet" {
  compartment_id    = oci_identity_compartment.crodrigues.id
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "10.15.16.0/20"
  # Use default route table - no custom route table needed
  security_list_ids = [oci_core_security_list.public_subnet_sl.id]
  display_name      = "virtual-nodes-public-api-subnet"
}

resource "oci_core_security_list" "public_subnet_sl" {
  compartment_id = oci_identity_compartment.crodrigues.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "virtual-nodes-public-api-subnet-sl"
  # Removed Service CIDR rule - using CIDR blocks instead
  egress_security_rules {
    stateless        = false
    description      = "All traffic to worker nodes"
    destination      = "10.15.0.0/20" #virtual-nodes-private-node-subnet-sl
    destination_type = "CIDR_BLOCK"
    protocol         = "all" #All traffic to worker nodes
  }
  egress_security_rules {
    stateless        = false
    description      = "Path discovery"
    destination      = "10.15.0.0/20" #virtual-nodes-private-node-subnet-sl
    destination_type = "CIDR_BLOCK"
    protocol         = "1"
    icmp_options { #Path discovery
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    stateless   = false
    description = "Kubernetes worker to Kubernetes API endpoint communication"
    source      = "10.15.0.0/20" #virtual-nodes-private-node-subnet-sl  
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options { #Kubernetes worker to Kubernetes API endpoint communication
      min = 6443
      max = 6443
    }
  }
  ingress_security_rules {
    stateless   = false
    description = "Kubernetes worker to control plane communication"
    source      = "10.15.0.0/20" #virtual-nodes-private-node-subnet-sl
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options { #Kubernetes worker to control plane communication
      min = 12250
      max = 12250
    }
  }
  ingress_security_rules {
    stateless   = false
    description = "Path discovery"
    source      = "0.0.0.0/0" #Path discovery to worker nodes from public subnet
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    icmp_options { #Path discovery
      type = 3
      code = 4
    }
  }
}

##### Service Subnet definitions #####
resource "oci_core_subnet" "vcn_service_subnet" {
  compartment_id    = oci_identity_compartment.crodrigues.id
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "10.15.32.0/20"
  # Use default route table - no custom route table needed
  security_list_ids = [oci_core_security_list.service_subnet_sl.id]
  display_name      = "virtual-nodes-service-lb-subnet"
}

resource "oci_core_security_list" "service_subnet_sl" {
  compartment_id = oci_identity_compartment.crodrigues.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "virtual-nodes-service-lb-subnet-sl"
  
  egress_security_rules {
    description      = "Allow all outbound traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }
  
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
  
  ingress_security_rules {
    description = "Allow NodePort range"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 30000
      max = 32767
    }
  }
}