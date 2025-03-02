resource "oci_identity_compartment" "vpn_aws_oci" {
  compartment_id = var.comp_crs
  description    = "Lab AWS OCI VPN Compartment"
  name           = "vpn-oci-aws"
  enable_delete  = true
}

resource "oci_core_vcn" "vcn_aws_oci" {
  compartment_id = oci_identity_compartment.vpn_aws_oci.id
  cidr_block     = "192.168.0.0/16"
  display_name   = "AWS OCI VCN"
  dns_label      = "vcnawsoci"
}

resource "oci_core_cpe" "aws_customer_gateway" {
  compartment_id = oci_identity_compartment.vpn_aws_oci.id
  ip_address     = "1.1.1.1" # IP público do Gateway VPN da AWS
  display_name   = "AWS Customer Gateway"

}

resource "oci_core_drg" "drg" {
    compartment_id = oci_identity_compartment.vpn_aws_oci.id
    display_name = "drg-oci-aws"
}

# resource "oci_core_ipsec" "ip_sec_connection" {
#     compartment_id = oci_identity_compartment.vpn_aws_oci.id
#     cpe_id = oci_core_cpe.aws_customer_gateway.id
#     drg_id = oci_core_drg.drg.id
#     static_routes = ["131.10.0.0/22"]
#     display_name = "ip_sec_connection"

# }

data "oci_core_virtual_circuits" "virtual_circuits" {
    #Required
    compartment_id = var.comp_crs

    #Optional
    display_name = "virtual_circuit"
    #state = var.virtual_circuit_state
}

# OCI IPSec Connection
resource "oci_core_ipsec" "ip_sec_connection" {
  compartment_id      = oci_identity_compartment.vpn_aws_oci.id
  display_name        = "OCI-AWS-1"
  cpe_id              = oci_core_cpe.aws_customer_gateway.id
  drg_id              = oci_core_drg.drg.id
  static_routes       = ["0.0.0.0/0"]
      tunnel_configuration {
        oracle_tunnel_ip = "10.1.5.5"
        associated_virtual_circuits = [oci_core_virtual_circuits.virtual_circuits.id]
        drg_route_table_id = oci_core_drg_route_table.test_drg_ipsec_over_fc_route_table.id
    }
    tunnel_configuration {
        oracle_tunnel_ip = "10.1.7.7"
        associated_virtual_circuits = [oci_core_virtual_circuits.virtual_circuits.id]
        drg_route_table_id = oci_core_drg_route_table.test_drg_ipsec_over_fc_route_table.id
    }

  # tunnel_configuration {
  #   display_name             = "AWS-TUNNEL-1"
  #   shared_secret            = "jsdjgf76"
  #   ike_version              = "V2"
  #   routing                  = "BGP"
  #   bgp_session_config {
  #     oracle_interface_ip = "169.254.20.2/30"
  #     customer_interface_ip = "169.254.20.1/30"
  #     oracle_bgp_asn = "31898"
  #     customer_bgp_asn = "64512"
  #   }
}

resource "oci_core_drg_attachment" "drg_attachment" {
  drg_id         = oci_core_drg.drg.id
  vcn_id         = oci_core_vcn.vcn_aws_oci.id
}

resource "oci_core_route_table" "aws_oci_rt" {
  compartment_id = oci_identity_compartment.vpn_aws_oci.id
  vcn_id         = oci_core_vcn.vcn_aws_oci.id
  display_name   = "aws_oci_rt"

  route_rules {
    destination       = "131.10.0.0/22" # Sub-rede da AWS
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
}

resource "oci_core_drg_route_table" "drg_route_table" {
    #Required
    drg_id = oci_core_drg.drg.id

    #Optional
    # defined_tags = {"Operations.CostCenter"= "42"}
    # display_name = var.drg_route_table_display_name
    # freeform_tags = {"Department"= "Finance"}
    # import_drg_route_distribution_id = oci_core_drg_route_distribution.test_drg_route_distribution.id
    # is_ecmp_enabled = var.drg_route_table_is_ecmp_enabled
}
