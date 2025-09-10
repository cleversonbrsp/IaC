# Simple Infrastructure - OCI

Este diretório contém uma infraestrutura simples no Oracle Cloud Infrastructure (OCI) usando Terraform.

## Configuração

### Pré-requisitos

1. **OCI CLI configurado** com o perfil `[devopsguide]` no arquivo `~/.oci/config`
2. **Terraform** instalado (versão >= 1.0)
3. **Chave SSH** configurada para acesso às instâncias

### Estrutura do Projeto

```
simple_infra/
├── main.tf              # Configuração do provider e terraform
├── variables.tf         # Definição das variáveis
├── terraform.tfvars     # Valores das variáveis
├── compartments.tf      # Criação do compartment
├── network.tf          # VCN, subnet, internet gateway e security list
├── instances.tf        # Instância EC2
├── output.tf           # Outputs da infraestrutura
└── README.md           # Este arquivo
```

### Configuração do Provider

O provider OCI está configurado para usar o perfil `[devopsguide]` do arquivo `~/.oci/config`:

```hcl
provider "oci" {
  config_file_profile = "devopsguide"
  region              = var.oci_region
}
```

### Variáveis Principais

- `oci_region`: Região do OCI (padrão: sa-saopaulo-1)
- `oci_ad`: Availability Domain
- `comp_id`: OCID do compartment pai
- `ssh_instances_key`: Chave SSH pública para as instâncias
- `instance_shape`: Shape da instância (padrão: VM.Standard.A1.Flex)
- `instance_memory_gb`: Memória em GB (padrão: 6)
- `instance_ocpus`: Número de OCPUs (padrão: 1)
- `vcn_cidr`: CIDR da VCN (padrão: 192.168.0.0/16)
- `subnet_cidr`: CIDR da subnet (padrão: 192.168.0.0/16)

### Como Usar

1. **Configure o arquivo `terraform.tfvars`** com os valores apropriados:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edite o arquivo com seus valores
   ```

2. **Inicialize o Terraform**:
   ```bash
   terraform init
   ```

3. **Valide a configuração**:
   ```bash
   terraform validate
   ```

4. **Planeje a execução**:
   ```bash
   terraform plan
   ```

5. **Aplique a configuração**:
   ```bash
   terraform apply
   ```

6. **Para destruir a infraestrutura**:
   ```bash
   terraform destroy
   ```

### Recursos Criados

- **Compartment**: `lab-01`
- **VCN**: `vcn-lab01` com CIDR 192.168.0.0/16
- **Subnet**: `pub_subnet` com CIDR 192.168.0.0/16
- **Internet Gateway**: `igw`
- **Security List**: `sec_list` (permite todo tráfego)
- **Instância**: `prod-clientA-webserver-001` (VM.Standard.A1.Flex)

### Outputs

Após a execução, os seguintes outputs estarão disponíveis:

- `instance_public_ip`: IP público da instância
- `instance_private_ip`: IP privado da instância
- `vcn_id`: OCID da VCN
- `subnet_id`: OCID da subnet
- `compartment_id`: OCID do compartment

### Notas Importantes

- A instância é criada com IP público habilitado
- A security list permite todo tráfego (não recomendado para produção)
- O compartment tem `enable_delete = true` para facilitar testes
- A chave SSH deve estar configurada corretamente para acesso à instância

### Troubleshooting

Se encontrar problemas de autenticação, verifique:

1. Se o perfil `[devopsguide]` existe em `~/.oci/config`
2. Se as credenciais estão corretas
3. Se o usuário tem as permissões necessárias no OCI
