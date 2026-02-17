variable "oci_user" {
  default = ""
}

variable "oci_fringerprint" {
  default = ""
}

variable "oci_region" {
  default = ""
}

variable "oci_apikey" {
  default = ""
}

variable "oci_root_tenancy" {
  default = ""
}

variable "oci_ad_agak" {
  default = ""
}

variable "node_img" {
  type    = string
  default = ""
}

variable "ssh_instances_key" {
  default = ""
}

variable "oci_region_us" {
  default = ""
}

variable "ubuntu_img" {
  default = ""
}

variable "ubuntu_image_ocid" {
  description = "OCID da imagem Ubuntu 2025.07.23-0. Se vazio, tentará buscar automaticamente."
  type        = string
  default     = ""
}

variable "oci_ad" {
  default = ""
}

variable "ad_ashburn" {
  default = ""
}

variable "source_id_sp" {
  default = ""
}

variable "source_id_ashburn" {
  default = ""
}

variable "comp_id" {
  default = ""
}

variable "steam_username" {
  description = "Nome de usuário Steam para instalação do DayZ Server. Se vazio, usa login anônimo. Se preenchido, será necessário autenticar manualmente na primeira vez (ou fornecer steam_password)."
  type        = string
  default     = ""
  sensitive   = false
}

variable "steam_password" {
  description = "⚠️ SENHA do Steam (opcional, NÃO RECOMENDADO por segurança). Se vazio e steam_username preenchido, será necessário autenticar manualmente. Se preenchido, a senha será passada ao SteamCMD (armazenada em texto plano no user-data)."
  type        = string
  default     = ""
  sensitive   = true
}