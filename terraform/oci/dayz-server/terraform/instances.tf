# ============================================================================
# INSTÂNCIA COMPUTE - SERVIDOR DAYZ
# ============================================================================
# Cria a instância Compute que hospedará o servidor DayZ.
# Esta instância será provisionada com Ubuntu 2025.07.23-0 e terá
# o script user-data.sh executado na primeira inicialização para
# instalar e configurar automaticamente o servidor DayZ.
# ============================================================================

resource "oci_core_instance" "dayz-server-instance" {
  availability_domain = var.oci_ad
  compartment_id      = var.comp_id
  display_name        = "dayz-server-instance"

  # Shape flexível - permite escolher OCPUs e RAM
  # VM.Standard.E4.Flex é compatível com imagens x86_64 (Ubuntu)
  # VM.Standard.A1.Flex é para ARM (Ampere) - não compatível com esta imagem
  shape = "VM.Standard.E4.Flex"

  # Configuração: 2 OCPUs e 16GB RAM (adequado para 10-20 jogadores)
  shape_config {
    memory_in_gbs = 16
    ocpus         = 2
  }

  # Configuração da interface de rede (VNIC)
  create_vnic_details {
    assign_private_dns_record = true   # Habilita DNS privado
    assign_public_ip          = true    # Atribui IP público para acesso externo
    subnet_id                 = oci_core_subnet.pub_subnet.id
  }

  # Metadados da instância
  metadata = {
    # Chave SSH pública para autenticação (sem senha)
    "ssh_authorized_keys" = var.ssh_instances_key
    
    # Script de inicialização (user-data) - executado na primeira inicialização
    # O script instala SteamCMD, configura firewall, cria usuário, etc.
    # Passa variáveis steam_username e steam_password para o script
    # "user_data" = base64encode(templatefile("${path.module}/../scripts/user-data.sh", {
    #   steam_username = var.steam_username != "" ? var.steam_username : "anonymous"
    #   steam_password = var.steam_password != "" ? var.steam_password : ""
    # }))
  }

  # Imagem do sistema operacional
  source_details {
    source_id   = var.ubuntu_image_ocid
    source_type = "image"
  }

  # Configuração do agente OCI
  # O agente permite gerenciamento e monitoramento da instância
  agent_config {
    is_management_disabled = false  # Habilita gerenciamento OCI
    is_monitoring_disabled  = false  # Habilita monitoramento OCI
  }

  # Não preservar boot volume ao deletar instância
  # Se true, o volume será mantido mesmo após deletar a instância
  preserve_boot_volume = false
}





  # agent_config {
  #   is_management_disabled = "false"
  #   is_monitoring_disabled = "false"
  #   plugins_config {
  #     desired_state = "ENABLED"
  #     name          = "Vulnerability Scanning"
  #   }
  #   plugins_config {
  #     desired_state = "ENABLED"
  #     name          = "Oracle Java Management Service"
  #   }
  #   plugins_config {
  #     desired_state = "ENABLED"
  #     name          = "OS Management Service Agent"
  #   }
  #   plugins_config {
  #     desired_state = "ENABLED"
  #     name          = "Compute Instance Run Command"
  #   }
  #   plugins_config {
  #     desired_state = "ENABLED"
  #     name          = "Compute Instance Monitoring"
  #   }
  #   plugins_config {
  #     desired_state = "ENABLED"
  #     name          = "Block Volume Management"
  #   }
  #   plugins_config {
  #     desired_state = "ENABLED"
  #     name          = "Bastion"
  #   }
  # }
  # availability_config {
  #   recovery_action = "RESTORE_INSTANCE"
  # }
    # instance_options {
  #   are_legacy_imds_endpoints_disabled = "false"
  # }
  # is_pv_encryption_in_transit_enabled = "true"