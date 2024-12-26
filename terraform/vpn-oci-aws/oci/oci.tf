terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 6.0"
    }
  }
}

provider "oci" {
  region = "sa-saopaulo-1"
}

resource "oci_identity_compartment" "vpn_aws_oci" {
  compartment_id = var.compartment_id
  description    = "AWS OCI VPN Compartment"
  name           = "vpn-oci-aws"
  enable_delete  = true
}

resource "oci_core_vcn" "vcn_aws_oci" {
  compartment_id = oci_identity_compartment.vpn_aws_oci.id
  cidr_block     = "10.0.0.0/16"
  display_name   = "AWS OCI VCN"
  dns_label      = "vcnawsoci"
}

resource "oci_core_cpe" "aws_customer_gateway" {
  compartment_id = oci_identity_compartment.vpn_aws_oci.id
  ip_address     = "198.51.100.1" # IP público do Gateway VPN da AWS
  display_name   = "AWS Customer Gateway"
  #defined_tags = {"Operations.CostCenter"= "42"}
  #freeform_tags = {"Department"= "Finance"}
  #is_private = var.cpe_is_private
}

resource "oci_core_drg" "drg" {
    compartment_id = oci_identity_compartment.vpn_aws_oci.id
    display_name = "drg-test"
    #defined_tags = {"Operations.CostCenter"= "42"}
    #freeform_tags = {"Department"= "Finance"}
}

resource "oci_core_ipsec" "test_ip_sec_connection" {
    compartment_id = oci_identity_compartment.vpn_aws_oci.id
    cpe_id = oci_core_cpe.aws_customer_gateway.id
    drg_id = oci_core_drg.drg.id
    static_routes = ["10.0.0.0/24"]
    display_name = "to-aws"

    #Optional
    #cpe_local_identifier = var.ip_sec_connection_cpe_local_identifier
    #cpe_local_identifier_type = var.ip_sec_connection_cpe_local_identifier_type
    #defined_tags = {"Operations.CostCenter"= "42"}
    #freeform_tags = {"Department"= "Finance"}
}

resource "oci_core_drg_attachment" "drg_attachment" {
  #compartment_id = oci_identity_compartment.vpn_aws_oci.id
  drg_id         = oci_core_drg.drg.id
  vcn_id         = oci_core_vcn.vcn_aws_oci.id
}

# resource "oci_core_route_table" "aws_oci_rt" {
#   compartment_id = oci_identity_compartment.vpn_aws_oci.id
#   vcn_id         = oci_core_vcn.vcn_aws_oci.id
#   display_name   = "AWS OCI Route Table"

#   route_rules {
#     destination       = "10.0.0.0/16" # Sub-rede da AWS
#     destination_type  = "CIDR_BLOCK"
#     network_entity_id = oci_core_drg.drg.id
#   }
# }
