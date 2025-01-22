variable "oci_user" {
  description = "OCID do usuário OCI"
  type        = string
}

variable "oci_region" {
  description = "Região OCI principal"
  type        = string
}

variable "oci_region_us" {
  description = "Região OCI secundária (US)"
  type        = string
}

variable "oci_apikey" {
  description = "Caminho para a chave privada da API OCI"
  type        = string
}

variable "oci_root_tenancy" {
  description = "OCID do root tenancy OCI"
  type        = string
}

variable "ssh_instances_key" {
  description = "Chave pública SSH usada para acesso às instâncias"
  type        = string
}

variable "oci_ad_agak" {
  description = "Domínio de disponibilidade (AD) na região São Paulo"
  type        = string
}

variable "node_img" {
  description = "OCID da imagem do nó"
  type        = string
}

variable "ubuntu_img" {
  description = "OCID da imagem Ubuntu"
  type        = string
}

variable "oci_ad" {
  description = "Domínio de disponibilidade (AD) primário"
  type        = string
}

variable "ad_ashburn" {
  description = "Domínio de disponibilidade (AD) em Ashburn"
  type        = string
}

variable "source_id_sp" {
  description = "OCID da imagem fonte em São Paulo"
  type        = string
}

variable "source_id_ashburn" {
  description = "OCID da imagem fonte em Ashburn"
  type        = string
}

variable "comp_id" {
  description = "OCID do compartment"
  type        = string
}
