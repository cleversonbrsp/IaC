# OKE Cluster with Virtual Nodes

Este diretório contém a configuração para criar um cluster OKE (Oracle Kubernetes Engine) com Virtual Nodes no Oracle Cloud Infrastructure (OCI).

## Arquitetura

O cluster OKE é configurado com:

- **VCN**: Rede virtual com CIDR 10.15.0.0/18
- **3 Subnets**:
  - **Private Subnet** (10.15.0.0/20): Para os virtual nodes
  - **Public Subnet** (10.15.16.0/20): Para o endpoint da API do Kubernetes
  - **Service Subnet** (10.15.32.0/20): Para Load Balancers de serviços
- **Virtual Node Pool**: Pool de nós virtuais com shape Pod.Standard.E4.Flex
- **CNI**: OCI VCN IP Native para networking nativo

## Recursos Criados

### Rede
- VCN com Internet Gateway e NAT Gateway
- 3 Subnets com route tables apropriadas
- Security Lists configuradas para comunicação entre componentes
- DHCP Options para resolução DNS

### Cluster OKE
- Cluster Kubernetes v1.33.1
- Endpoint público habilitado
- Configuração de rede nativa do OCI
- CIDR para pods: 10.244.0.0/16
- CIDR para serviços: 10.96.0.0/18

### Virtual Node Pool
- 3 virtual nodes
- Shape: Pod.Standard.E4.Flex
- Distribuído em múltiplas fault domains
- Labels e configurações de pod

## Configuração

### Pré-requisitos

1. **OCI CLI configurado** com o perfil `[devopsguide]` no arquivo `~/.oci/config`
2. **Terraform** instalado (versão >= 1.0)
3. **Compartment** existente no OCI

### Variáveis

Configure as seguintes variáveis no arquivo `terraform.tfvars`:

```hcl
oci_region = "sa-saopaulo-1"
oci_ad     = "agak:SA-SAOPAULO-1-AD-1"
comp_id    = "ocid1.tenancy.oc1..aaaaaaaazjhsdvngrxxref2sykfxkpqonubj3i5yii6o3wv2tjy7inoqfjba"
```

### Como Usar

1. **Configure o arquivo `terraform.tfvars`** com os valores apropriados
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

## Correções Realizadas

### Problemas Identificados
O arquivo `network.tf` estava referenciando recursos não declarados:
- `oci_core_dhcp_options.private-dhcp-options-for-oke-vcn-prod`
- `oci_core_route_table.generated_oci_core_route_table`
- `oci_core_route_table.generated_oci_core_public_route_table`
- `oci_core_security_list.service_subnet_sl`

### Soluções Implementadas
1. **Adicionado DHCP Options** para resolução DNS na subnet privada
2. **Criadas Route Tables**:
   - Private route table com rota para NAT Gateway
   - Public route table com rota para Internet Gateway
3. **Adicionado Security List** para service subnet com regras para:
   - HTTP (porta 80)
   - HTTPS (porta 443)
   - NodePort range (30000-32767)
   - Tráfego de saída completo

## Segurança

### Security Lists Configuradas
- **Private Subnet**: Comunicação entre pods e com control plane
- **Public Subnet**: Acesso à API do Kubernetes
- **Service Subnet**: Load balancers e serviços expostos

### Networking
- Subnet privada sem IPs públicos
- NAT Gateway para acesso à internet dos virtual nodes
- Internet Gateway para endpoint público da API

## Troubleshooting

### Problemas Comuns
1. **Erro de autenticação**: Verifique se o perfil `[devopsguide]` está configurado corretamente
2. **Erro de permissões**: Certifique-se de que o usuário tem as permissões necessárias
3. **Erro de quota**: Verifique se há recursos suficientes na região

### Logs Úteis
- Use `terraform plan` para verificar mudanças antes de aplicar
- Use `terraform show` para ver o estado atual
- Use `terraform destroy` para remover todos os recursos

## Próximos Passos

Após criar o cluster:
1. Configure o `kubeconfig` para acessar o cluster
2. Instale add-ons necessários (CNI, ingress controller, etc.)
3. Configure namespaces e RBAC
4. Deploy aplicações no cluster
