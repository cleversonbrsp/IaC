variable "shared_secret" {
  description = "Chave pré-compartilhada para a conexão IPSec"
  type        = string
}

variable "oc_bgp_asn" {
  description = "ASN do BGP para a Oracle Cloud"
  type        = number
  default     = 31898 # Ajuste conforme necessário
}

variable "aws_bgp_asn" {
  description = "ASN do BGP para a AWS"
  type        = number
  default     = 64512 # Ajuste conforme necessário
}

variable "comp_crs" {
  default = "Cleverson's Root Compartment"
}

variable "vcn_itau_prod" {
  default = " VCN Itau PROD Isolada"
}