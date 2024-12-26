variable "tenancy_ocid" {
  description = "OCID do Tenancy na Oracle Cloud"
  type        = string
}

variable "user_ocid" {
  description = "OCID do usuário na Oracle Cloud"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint da chave API para a Oracle Cloud"
  type        = string
}

variable "private_key_path" {
  description = "Caminho para a chave privada usada na Oracle Cloud"
  type        = string
}

variable "region" {
  description = "Região da Oracle Cloud"
  type        = string
  default     = ""
}

variable "compartment_id" {
  description = "OCID do compartimento na Oracle Cloud"
  type        = string
}

variable "aws_vpn_ip" {
  description = "Endereço IP do Gateway Virtual Privado da AWS"
  type        = string
}

variable "oci_vpn_ip" {
  description = "Endereço IP da VPN da Oracle para o túnel"
  type        = string
}

variable "shared_secret" {
  description = "Chave pré-compartilhada para a conexão IPSec"
  type        = string
}

variable "oc_bgp_asn" {
  description = "ASN do BGP para a Oracle Cloud"
  type        = number
  default     = 31898  # Ajuste conforme necessário
}

variable "aws_bgp_asn" {
  description = "ASN do BGP para a AWS"
  type        = number
  default     = 64512  # Ajuste conforme necessário
}