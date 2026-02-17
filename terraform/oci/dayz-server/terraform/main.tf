# ============================================================================
# CONFIGURAÇÃO DO TERRAFORM E PROVIDER OCI
# ============================================================================
# Este arquivo configura o Terraform e o provider Oracle Cloud Infrastructure
# para provisionar a infraestrutura do servidor DayZ.

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~>7.30.0"  # Versão mínima 7.30.0, permite patches (7.30.x)
    }
  }
  # Nota: Se você ver erro de versão, execute: terraform init -upgrade
}

# ============================================================================
# PROVIDER OCI
# ============================================================================
# Configuração do provider OCI usando perfil de autenticação.
# O perfil "devopsguide" deve estar configurado em ~/.oci/config
#
# Exemplo de ~/.oci/config:
# [devopsguide]
# user=ocid1.user.oc1..aaaaaaa...
# fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
# tenancy=ocid1.tenancy.oc1..aaaaaaa...
# region=sa-saopaulo-1
# key_file=~/.oci/devopsguide_private_key.pem
#
# Alternativamente, você pode descomentar as linhas abaixo e usar variáveis
# para autenticação direta (menos seguro, não recomendado).
# ============================================================================

provider "oci" {
  # Usa o perfil "devopsguide" do arquivo ~/.oci/config
  config_file_profile = "devopsguide"
  region              = var.oci_region  # Região OCI (ex: sa-saopaulo-1)
  
  # Opções alternativas de autenticação (descomente se necessário):
  # tenancy_ocid     = var.oci_root_tenancy
  # user_ocid        = var.oci_user
  # private_key_path = var.oci_apikey
  # fingerprint      = var.oci_fringerprint
}