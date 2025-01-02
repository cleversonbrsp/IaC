provider "aws" {
  region = "us-east-1"
}

# # VPC
# resource "aws_vpc" "example_vpc" {
#   cidr_block = "10.0.0.0/16"
#   enable_dns_support = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "example_vpc"
#   }
# }

# Gateway Virtual Privado
resource "aws_vpn_gateway" "example_vpn_gateway" {
  vpc_id = "vpc-0c003607e3fe9a2b0"

  tags = {
    Name = "gtw-itau-isolado"
  }

#  depends_on = [aws_vpc.example_vpc] # Garantir que a VPC seja criada primeiro
}

# Gateway Client Temporário
resource "aws_customer_gateway" "temp_gateway" {
  bgp_asn    = 65000
  ip_address = "203.0.113.1" # IP público temporário
  type       = "ipsec.1"

  tags = {
    Name = "gtw-temp-itau-isolado"
  }
}

# Conexão VPN com o Gateway Temporário
resource "aws_vpn_connection" "temp_vpn_connection" {
  vpn_gateway_id      = aws_vpn_gateway.example_vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.temp_gateway.id
  type                = "ipsec.1"
  static_routes_only  = true

  depends_on = [
    aws_vpn_gateway.example_vpn_gateway, 
    aws_customer_gateway.temp_gateway
  ] # Garantir que o gateway e o cliente estejam criados
}

# Gateway Client Final
resource "aws_customer_gateway" "final_gateway" {
  bgp_asn    = 65001
  ip_address = "198.51.100.1" # IP público real do ponto final da VPN do OCI
  type       = "ipsec.1"

  tags = {
    Name = "final-gtw-itau-isolado"
  }
}

# Conexão VPN com o Gateway final (opcional)
resource "aws_vpn_connection" "final_vpn_connection" {
  vpn_gateway_id      = aws_vpn_gateway.example_vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.final_gateway.id
  type                = "ipsec.1"
  static_routes_only  = true

  depends_on = [
    aws_customer_gateway.final_gateway, 
    aws_vpn_gateway.example_vpn_gateway
  ] # Garantir que os gateways estejam criados
}