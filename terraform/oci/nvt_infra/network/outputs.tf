# ========================================
# Network Outputs
# ========================================

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.nvt_infra_vcn.id
}

output "vcn_cidr_block" {
  description = "CIDR block of the VCN"
  value       = oci_core_vcn.nvt_infra_vcn.cidr_block
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  value       = oci_core_internet_gateway.nvt_infra_igw.id
}

output "nat_gateway_id" {
  description = "OCID of the NAT Gateway"
  value       = oci_core_nat_gateway.nvt_infra_nat_gw.id
}

output "service_gateway_id" {
  description = "OCID of the Service Gateway"
  value       = oci_core_service_gateway.nvt_infra_sg.id
}

output "oke_api_endpoint_subnet_id" {
  description = "OCID of the OKE API endpoint subnet"
  value       = oci_core_subnet.oke_api_endpoint_subnet.id
}

output "oke_node_subnet_id" {
  description = "OCID of the OKE node subnet"
  value       = oci_core_subnet.oke_node_subnet.id
}

output "oke_lb_subnet_id" {
  description = "OCID of the OKE load balancer subnet"
  value       = oci_core_subnet.oke_lb_subnet.id
}

output "vpn_subnet_id" {
  description = "OCID of the VPN subnet"
  value       = oci_core_subnet.vpn_subnet.id
}

output "db_subnet_id" {
  description = "OCID of the database subnet"
  value       = oci_core_subnet.db_subnet.id
}

output "private_route_table_id" {
  description = "OCID of the private route table"
  value       = oci_core_route_table.private_route_table.id
}

