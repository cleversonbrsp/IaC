terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 6.0"
    }
  }
}

provider "oci" {
  region = "us-ashburn-1"
}

# resource "oci_identity_compartment" "vpn_aws_oci" {
#   compartment_id = var.compartment_id
#   description    = "AWS OCI VPN Compartment"
#   name           = "vpn-oci-aws"
#   enable_delete  = true
# }

# resource "oci_core_vcn" "vcn_aws_oci" {
#   compartment_id = var.comp_itau_prod
#   cidr_block     = "10.0.0.0/16"
#   display_name   = "AWS OCI VCN"
#   dns_label      = "vcnawsoci"
# }

resource "oci_core_cpe" "aws_customer_gateway" {
  compartment_id = var.comp_itau_prod
  ip_address     = "198.51.100.1" # IP público do Gateway VPN da AWS
  display_name   = "AWS Customer Gateway"
  defined_tags = {"costs.total"= "itau"}
  #freeform_tags = {"Department"= "Finance"}
  #is_private = var.cpe_is_private
}

resource "oci_core_drg" "drg" {
    compartment_id = var.comp_itau_prod
    display_name = "drg-itau-isolado"
    defined_tags = {"costs.total"= "itau"}
    #freeform_tags = {"Department"= "Finance"}
}

resource "oci_core_ipsec" "test_ip_sec_connection" {
    compartment_id = var.comp_itau_prod
    cpe_id = oci_core_cpe.aws_customer_gateway.id
    drg_id = oci_core_drg.drg.id
    static_routes = ["131.10.0.0/22"]
    display_name = "gtw-itau-isolado"

    #Optional
    #cpe_local_identifier = var.ip_sec_connection_cpe_local_identifier
    #cpe_local_identifier_type = var.ip_sec_connection_cpe_local_identifier_type
    #defined_tags = {"Operations.CostCenter"= "42"}
    #freeform_tags = {"Department"= "Finance"}
}

resource "oci_core_drg_attachment" "drg_attachment" {
  #compartment_id = var.comp_itau_prod
  drg_id         = oci_core_drg.drg.id
  vcn_id         = var.vcn_itau_prod
}

resource "oci_core_route_table" "aws_oci_rt" {
  compartment_id = var.comp_itau_prod
  vcn_id         = var.vcn_itau_prod
  display_name   = "rota-itau-isolado"

  route_rules {
    destination       = "131.10.0.0/22" # Sub-rede da AWS
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
}
