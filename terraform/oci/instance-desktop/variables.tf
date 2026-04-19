variable "oci_region" {
  description = "Região OCI onde a VCN e a instância serão criadas (ex.: us-ashburn-1)."
  type        = string
  default     = "us-ashburn-1"
}

variable "oci_home_region" {
  description = "Região HOME da tenancy (Identity: compartment criado/atualizado só aqui)."
  type        = string
}

variable "oci_config_profile" {
  description = "Profile do ~/.oci/config (vazio = DEFAULT)."
  type        = string
  default     = ""
}

variable "tenancy_ocid" {
  description = "OCID da tenancy (campo tenancy em ~/.oci/config). Neste stack, documentação/outputs; pode ficar vazio."
  type        = string
  default     = ""
}

variable "parent_compartment_id" {
  description = "OCID do compartment PAI onde o Terraform criará o compartment filho."
  type        = string
  validation {
    condition     = length(var.parent_compartment_id) > 0 && can(regex("^ocid1\\.compartment\\.", var.parent_compartment_id))
    error_message = "parent_compartment_id precisa ser um OCID de compartment (ocid1.compartment...)."
  }
}

variable "compartment_name" {
  description = "Nome do compartment filho criado para o desktop na nuvem."
  type        = string
  default     = "desktop-instances"
}

variable "compartment_description" {
  description = "Descrição do compartment filho."
  type        = string
  default     = "Desktop Ubuntu + OpenVPN — subnet privada + NAT; SSH/RDP ao desktop via VPN"
}

variable "compartment_propagation_delay" {
  description = "Espera após criar o compartment (home) antes de criar recursos na oci_region."
  type        = string
  default     = "45s"
}

variable "common_tags" {
  description = "defined_tags aplicados aos recursos que suportam."
  type = object({
    defined_tags = map(string)
  })
  default = {
    defined_tags = {}
  }
}

# --- Rede ---

variable "vcn_cidr" {
  description = "CIDR da VCN (/16)."
  type        = string
  default     = "10.60.0.0/16"
  validation {
    condition     = can(cidrhost(var.vcn_cidr, 0)) && tonumber(split("/", var.vcn_cidr)[1]) == 16
    error_message = "vcn_cidr precisa ser /16 (ex.: 10.60.0.0/16)."
  }
}

variable "vcn_display_name" {
  description = "display_name da VCN."
  type        = string
  default     = "instance-desktop-vcn"
}

variable "vcn_dns_label" {
  description = "dns_label da VCN (minúsculo, sem espaços)."
  type        = string
  default     = "instancedesk"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,14}$", var.vcn_dns_label))
    error_message = "vcn_dns_label deve ter 1-15 chars, começar com letra, e conter apenas [a-z0-9]."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR da subnet privada (/24) onde fica o desktop. Tráfego de saída: NAT + Service Gateway."
  type        = string
  default     = "10.60.10.0/24"
}

variable "vpn_subnet_cidr" {
  description = "CIDR da subnet pública onde fica a instância OpenVPN (deve caber em vcn_cidr e não sobrepor private_subnet_cidr)."
  type        = string
  default     = "10.60.20.0/24"
  validation {
    condition     = can(cidrhost(var.vpn_subnet_cidr, 0)) && var.vpn_subnet_cidr != "0.0.0.0/0"
    error_message = "vpn_subnet_cidr deve ser um CIDR válido (não use 0.0.0.0/0)."
  }
}

variable "openvpn_client_cidr" {
  description = "CIDR usado nas regras do desktop (deve coincidir com o pool do servidor no script OpenVPN: 10.8.0.0/24)."
  type        = string
  default     = "10.8.0.0/24"
  validation {
    condition     = can(cidrhost(var.openvpn_client_cidr, 0)) && var.openvpn_client_cidr != "0.0.0.0/0"
    error_message = "openvpn_client_cidr deve ser um CIDR válido (não use 0.0.0.0/0)."
  }
}

variable "extra_admin_cidrs" {
  description = "CIDRs extras para SSH/RDP (ex.: bastion /32). Opcional."
  type        = list(string)
  default     = []
}

variable "openvpn_port" {
  description = "Porta UDP do servidor OpenVPN (deve coincidir com a security list da subnet VPN)."
  type        = number
  default     = 1194
}

variable "vpn_ssh_ingress_cidr" {
  description = "CIDR permitido para SSH (22) na instância OpenVPN (IP público)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "openvpn_udp_ingress_cidr" {
  description = "CIDR de origem para UDP na porta OpenVPN (normalmente 0.0.0.0/0)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpn_instance_display_name" {
  description = "display_name da instância OpenVPN."
  type        = string
  default     = "openvpn"
}

variable "vpn_instance_shape" {
  description = "Shape da instância OpenVPN."
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "vpn_instance_ocpus" {
  description = "OCPUs da instância OpenVPN (shapes Flex)."
  type        = number
  default     = 1
}

variable "vpn_instance_memory_gbs" {
  description = "Memória (GB) da instância OpenVPN (shapes Flex)."
  type        = number
  default     = 6
}

variable "vpn_image_id" {
  description = "OCID da imagem da VPN (vazio = usa instance_image_id)."
  type        = string
  default     = ""
}

variable "vpn_instance_hostname_label" {
  description = "hostname_label da VNIC OpenVPN."
  type        = string
  default     = "openvpn"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,14}$", var.vpn_instance_hostname_label))
    error_message = "vpn_instance_hostname_label: 1-15 chars, [a-z0-9], começa com letra."
  }
}

# --- Compute ---

variable "availability_domain_name" {
  description = "Nome do Availability Domain (ex.: YCyV:US-ASHBURN-AD-1)."
  type        = string
  default     = ""
  validation {
    condition     = var.availability_domain_name == "" || can(regex("^[A-Za-z0-9]+:.+-AD-[0-9]+$", var.availability_domain_name))
    error_message = "availability_domain_name deve estar no formato <prefixo>:<REGION>-AD-N (ex.: YCyV:US-ASHBURN-AD-1)."
  }
}

variable "instance_display_name" {
  description = "display_name da instância."
  type        = string
  default     = "ubuntu-desktop"
}

variable "instance_hostname_label" {
  description = "hostname_label da VNIC (1-15 caracteres, [a-z0-9], começa com letra)."
  type        = string
  default     = "ubuntudesk"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,14}$", var.instance_hostname_label))
    error_message = "instance_hostname_label deve ter 1-15 chars, começar com letra, e conter apenas [a-z0-9]."
  }
}

variable "instance_shape" {
  description = "Shape da instância."
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "instance_ocpus" {
  description = "OCPUs (para shapes Flex)."
  type        = number
  default     = 4
}

variable "instance_memory_gbs" {
  description = "Memória em GB (para shapes Flex)."
  type        = number
  default     = 64
}

variable "instance_image_id" {
  description = "OCID da imagem (Ubuntu/Jammy ou conforme região)."
  type        = string
  validation {
    condition     = length(var.instance_image_id) > 0 && can(regex("^ocid1\\.image\\.", var.instance_image_id))
    error_message = "instance_image_id precisa ser um OCID de imagem (ocid1.image...)."
  }
}

variable "ssh_public_key_path" {
  description = "Caminho da chave SSH pública (arquivo) na máquina que roda terraform apply."
  type        = string
}

variable "ssh_private_key_path" {
  description = "Caminho da chave SSH privada correspondente (usada no output ssh_cmd)."
  type        = string
  default     = "~/.ssh/instance-oci.key"
}

variable "cloud_init_user" {
  description = "Usuário Linux padrão da imagem (Ubuntu na OCI costuma ser ubuntu)."
  type        = string
  default     = "ubuntu"
}

variable "boot_volume_size_in_gbs" {
  description = "Tamanho do boot volume em GB."
  type        = number
  default     = 100
  validation {
    condition     = var.boot_volume_size_in_gbs >= 50
    error_message = "boot_volume_size_in_gbs precisa ser >= 50 GB."
  }
}
