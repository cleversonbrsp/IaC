# Terraform Configuration

Esta pasta contém todos os arquivos de configuração do Terraform para provisionar a infraestrutura do servidor DayZ na OCI.

## Arquivos

- `main.tf` - Configuração do provider OCI
- `variables.tf` - Definição de variáveis
- `network.tf` - Configuração de rede (VCN, Subnet, Security Lists)
- `instances.tf` - Configuração da instância Compute
- `outputs.tf` - Outputs do Terraform
- `terraform.tfvars` - Valores das variáveis (não versionar - copie de `terraform.tfvars.example`)

## Uso

Todos os comandos Terraform devem ser executados dentro desta pasta:

```bash
cd terraform
terraform init -upgrade
terraform plan
terraform apply
```

**Nota sobre arquivos de estado**: Os arquivos de estado do Terraform (`terraform.tfstate`, `terraform.tfstate.backup`, `.terraform/`, etc.) são criados automaticamente nesta pasta quando você executa os comandos Terraform aqui. Eles foram movidos da raiz para manter a organização.

Veja o README.md principal na raiz do projeto para instruções completas.
