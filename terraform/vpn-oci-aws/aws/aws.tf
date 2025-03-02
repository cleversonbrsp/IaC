provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "vpc_crs" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_crs"
  }
}

# Temporary Customer Gateway
resource "aws_customer_gateway" "temp_gateway" {
  bgp_asn    = 31898
  ip_address = "1.1.1.1"
  type       = "ipsec.1"

  tags = {
    Name = "TempGateway"
  }
}

# Virtual Private Gateway (VPG)
resource "aws_vpn_gateway" "vpg" {
  amazon_side_asn = "64512"  # Default Amazon ASN

  tags = {
    Name = "crs-vpg"
  }
}

# Attach Virtual Private Gateway to VPC
resource "aws_vpn_gateway_attachment" "vpg_attachment" {
  vpc_id          = aws_vpc.vpc_crs.id
  vpn_gateway_id  = aws_vpn_gateway.vpg.id

  depends_on = [aws_vpn_gateway.vpg]
}

# VPN Connection
resource "aws_vpn_connection" "vpn_connection" {
  vpn_gateway_id      = aws_vpn_gateway.vpg.id
  customer_gateway_id = aws_customer_gateway.temp_gateway.id
  type                = "ipsec.1"
  tunnel1_inside_cidr = "169.254.20.0/30"  # Ensure this CIDR is allowed by OCI
  tunnel1_preshared_key = "Xy7pLm9Qz42sD"

  tags = {
    Name = "crs-vpn-connection"
  }

  depends_on = [aws_vpn_gateway_attachment.vpg_attachment]
}
