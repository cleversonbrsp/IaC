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

  depends_on = [
    oci_identity_compartment.vpn_aws_oci
  ]
}

resource "oci_core_drg" "drg" {
  compartment_id = oci_identity_compartment.vpn_aws_oci.id
  display_name   = "drg-oci-aws"

  depends_on = [
    oci_identity_compartment.vpn_aws_oci
  ]
}

resource "oci_core_cpe" "aws_customer_gateway" {
  compartment_id = oci_identity_compartment.vpn_aws_oci.id
  ip_address     = "1.1.1.1" # Substituir pelo IP real do AWS Customer Gateway
  display_name   = "TO_AWS"

  depends_on = [
    oci_identity_compartment.vpn_aws_oci
  ]
}

resource "oci_core_ipsec" "ip_sec_connection" {
  compartment_id = oci_identity_compartment.vpn_aws_oci.id
  cpe_id         = oci_core_cpe.aws_customer_gateway.id
  drg_id         = oci_core_drg.drg.id
  static_routes  = ["0.0.0.0/0"]
  display_name   = "OCI-AWS-1"
  tunnel_configuration {
    oracle_tunnel_ip = "10.1.5.5"
    #associated_virtual_circuits = [oci_core_virtual_circuit.test_ipsec_over_fc_virtual_circuit.id]
    drg_route_table_id = oci_core_drg_route_table.drg_route_table.id
}
tunnel_configuration {
    oracle_tunnel_ip = "10.1.7.7"
    #associated_virtual_circuits = [oci_core_virtual_circuit.test_ipsec_over_fc_virtual_circuit.id]
    drg_route_table_id = oci_core_drg_route_table.drg_route_table.id
    }

  depends_on = [
    oci_core_cpe.aws_customer_gateway,
    oci_core_drg.drg
  ]
}

# resource "oci_core_ipsec_connection_tunnel_management" "ipsec_tunnel_1" {
#   ipsec_id     = oci_core_ipsec.ip_sec_connection.id
#   tunnel_id    = 1
#   display_name = "AWS-TUNNEL-1"
#   routing      = "STATIC"
#   shared_secret = "Xy7pLm9Qz42sD"
#   ike_version  = "V2"
#   bgp_session_info {
#     customer_bgp_asn       = 64512
#     customer_interface_ip  = "169.254.20.2"
#     oracle_interface_ip    = "169.254.20.1"
# }

#   depends_on = [
#     oci_core_ipsec.ip_sec_connection
#   ]
# }

# resource "oci_core_ipsec_connection_tunnel_management" "ipsec_tunnel_2" {
#   ipsec_id     = oci_core_ipsec.ip_sec_connection.id
#   tunnel_id    = 2
#   display_name = "AWS-TUNNEL-2"
#   routing      = "STATIC"
#   shared_secret = "Xy7pLm9Qz42sD"
#   ike_version  = "V2"
#   bgp_session_info {
#     customer_bgp_asn       = 64512
#     customer_interface_ip  = "169.254.20.1"
#     oracle_interface_ip    = "169.254.20.2"
# }


#   depends_on = [
#     oci_core_ipsec.ip_sec_connection
#   ]
# }

resource "oci_core_drg_attachment" "drg_attachment" {
  drg_id = oci_core_drg.drg.id
  vcn_id = oci_core_vcn.vcn_aws_oci.id

  depends_on = [
    oci_core_vcn.vcn_aws_oci,
    oci_core_drg.drg
  ]
}

resource "oci_core_route_table" "aws_oci_rt" {
  compartment_id = oci_identity_compartment.vpn_aws_oci.id
  vcn_id         = oci_core_vcn.vcn_aws_oci.id
  display_name   = "aws_oci_rt"

  route_rules {
    destination       = "10.0.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  depends_on = [
    oci_core_vcn.vcn_aws_oci,
    oci_core_drg.drg
  ]
}

resource "oci_core_drg_route_table" "drg_route_table" {
  drg_id = oci_core_drg.drg.id

  depends_on = [
    oci_core_drg.drg
  ]
}
