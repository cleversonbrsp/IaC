# Usage2ADW - Oracle Cloud Infrastructure Usage and Cost Reports to Autonomous Database

Este projeto implementa a solução **Usage2ADW** usando Terraform, baseado no guia oficial [oracle-samples/usage-reports-to-adw](https://github.com/oracle-samples/usage-reports-to-adw).

## 📋 Visão Geral

O Usage2ADW é uma ferramenta que utiliza o Python SDK para extrair relatórios de uso e custo do seu tenant OCI e carregá-los em um Autonomous Database. O Oracle Application Express (APEX) é usado para relatórios e dashboards.

## 🏗️ Arquitetura

### Recursos Provisionados
- **VCN**: `192.168.0.0/16` com subnets privada e pública
- **Autonomous Database**: Para armazenar dados de uso e custo
- **Compute Instance**: VM que executa os scripts de extração
- **Network Security Groups**: Para ADW Private Endpoint (se habilitado)
- **Load Balancer**: Opcional, para acesso público ao APEX via Private Endpoint
- **IAM**: Dynamic Group e Policies para acesso aos recursos

### Estrutura de Rede
```
VCN (192.168.0.0/16)
├── Private Subnet (192.168.1.0/24) - VM + ADW Private Endpoint
├── Public Subnet (192.168.2.0/24) - Load Balancer (opcional)
├── Internet Gateway
├── NAT Gateway  
└── Service Gateway
```

## ⚠️ Importante

- **Deve ser implantado no Home Region**
- **VCN deve ter acesso à internet** via Internet Gateway ou NAT Gateway
- **Utiliza Vault Secret** para senha do banco de dados
- **Não é uma aplicação oficial Oracle** - não suportada pelo Oracle Support

## 🔧 Pré-requisitos

### 1. Terraform e Credenciais
- Terraform >= 1.3
- Credenciais OCI configuradas (`~/.oci/config` ou variáveis de ambiente)

### 2. Recursos OCI Existentes
- **Vault Secret**: Contendo senha do ADW que atenda aos critérios de complexidade
- **Compartment**: Onde os recursos serão criados
- **Tenancy OCID**: Do seu tenant OCI

### 3. Critérios da Senha do ADW
- **Comprimento**: Entre 12 e 30 caracteres
- **Tipos de caracteres**: Pelo menos 1 maiúscula, 1 minúscula, 1 numérico
- **Símbolos**: Apenas "#" é permitido
- **Não pode conter**: Nome de usuário ou palavras do dicionário

## 📁 Estrutura do Projeto

```
terraform/oci/usage-reports-to-adw/
├── providers.tf              # Configuração do provider OCI
├── variables.tf              # Todas as variáveis do projeto
├── main.tf                   # Orquestração dos módulos
├── network.tf                # VCN, subnets e security lists
├── autonomous_database.tf    # Módulo ADW
├── iam_policies.tf           # Módulo IAM (Dynamic Groups e Policies)
├── object_storage.tf         # Placeholder (não cria buckets)
├── event_rules.tf            # Placeholder (não cria eventos)
├── notifications.tf          # Placeholder (não cria notificações)
├── outputs.tf                # Outputs úteis
├── terraform.tfvars.example  # Exemplo de variáveis
├── terraform.tfvars          # Suas variáveis (não commitar)
└── README.md                 # Este arquivo
```

## 🚀 Como Usar

### 1. Configurar Variáveis

```bash
# Copie o exemplo
cp terraform.tfvars.example terraform.tfvars

# Edite com seus valores reais
nano terraform.tfvars
```

### 2. Variáveis Obrigatórias

```hcl
# Identificadores OCI
tenancy_ocid      = "ocid1.tenancy.oc1..aaaaaa..."
region            = "us-ashburn-1"  # Home Region
compartment_ocid  = "ocid1.compartment.oc1..bbbbbb..."

# Database
db_secret_compartment_id = "ocid1.compartment.oc1..cccccc..." # Compartment do Vault
db_secret_id             = "ocid1.vaultsecret.oc1..dddddd..." # Secret com senha ADW

# Compute
ssh_public_key                = "ssh-rsa AAAAB3NzaC1yc2E..."
instance_availability_domain  = "AD-1"
```

### 3. Executar Terraform

```bash
# Inicializar
terraform init

# Validar configuração
terraform validate

# Ver plano de execução
terraform plan -out plan.tfplan

# Aplicar mudanças
terraform apply plan.tfplan
```

### 4. Acessar APEX

Após o `terraform apply`, verifique os outputs:

```bash
terraform output APEX_Application_Login_URL
```

Acesse a URL retornada para usar a aplicação APEX.

## 🔐 Configuração de Credenciais

### Opção 1: Arquivo de Configuração
```bash
# ~/.oci/config
[DEFAULT]
tenancy=ocid1.tenancy.oc1..aaaaaa...
user=ocid1.user.oc1..bbbbbb...
fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
key_file=~/.oci/oci_api_key.pem
region=us-ashburn-1

[devopsguide]
tenancy=ocid1.tenancy.oc1..aaaaaa...
user=ocid1.user.oc1..bbbbbb...
fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
key_file=~/.oci/oci_api_key.pem
region=us-ashburn-1
```

**Este projeto usa o perfil `devopsguide` por padrão.**

### Opção 2: Variáveis de Ambiente
```bash
export TF_VAR_tenancy_ocid="ocid1.tenancy.oc1..aaaaaa..."
export TF_VAR_region="us-ashburn-1"
export TF_VAR_compartment_ocid="ocid1.compartment.oc1..bbbbbb..."
# ... outras variáveis necessárias
```

## 📊 Variáveis Principais

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `tenancy_ocid` | OCID do Tenancy | `ocid1.tenancy.oc1..aaaaaa...` |
| `region` | Região OCI (Home Region) | `us-ashburn-1` |
| `oci_config_profile` | Perfil OCI em ~/.oci/config | `devopsguide` |
| `compartment_ocid` | Compartment dos recursos | `ocid1.compartment.oc1..bbbbbb...` |
| `db_db_name` | Nome do ADW | `USAGE2ADW` |
| `db_secret_id` | Secret do Vault | `ocid1.vaultsecret.oc1..dddddd...` |
| `option_autonomous_database` | Tipo de endpoint | `Public Endpoint` ou `Private Endpoint` |
| `instance_shape` | Shape da VM | `VM.Standard.E4.Flex` |
| `extract_from_date` | Data início extração | `2023-01` |

## 🏷️ Tags

O projeto aplica tags consistentes em todos os recursos:

```hcl
service_tags = {
  freeformTags = {
    Project     = "Usage2ADW"
    Environment = "Production"
    Owner       = "DevOps"
    CostCenter  = "IT"
  }
  definedTags = {}
}
```

## 🔄 Comandos Úteis

```bash
# Verificar estado
terraform show

# Listar outputs
terraform output

# Destruir recursos
terraform destroy

# Formatar código
terraform fmt -recursive

# Validar configuração
terraform validate
```

## 🆘 Troubleshooting

### Problema: "Module not installed"
```bash
terraform init
```

### Problema: "Invalid credentials"
- Verifique `~/.oci/config` ou variáveis de ambiente
- Confirme fingerprint e chave privada

### Problema: "Password does not meet complexity requirements"
- A senha no Vault Secret deve atender aos critérios de complexidade
- Use pelo menos 12 caracteres com maiúscula, minúscula e número

### Problema: "APEX not accessible"
- Aguarde ~10 minutos após o `terraform apply`
- Verifique se a VM terminou o bootstrap (arquivo `boot.log`)
- Confirme se o ADW está no estado `AVAILABLE`

## 📚 Referências

- [Oracle Samples - Usage Reports to ADW](https://github.com/oracle-samples/usage-reports-to-adw)
- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Autonomous Database Documentation](https://docs.oracle.com/en/cloud/paas/autonomous-database/)
- [OCI Vault Documentation](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm)

## ⚖️ Disclaimer

Este não é um aplicativo oficial da Oracle. Não é suportado pelo Oracle Support e não deve ser usado para cálculos de utilização. Use os recursos oficiais de [análise de custo](https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/costanalysisoverview.htm) e [relatórios de uso](https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/usagereportsoverview.htm) do OCI.