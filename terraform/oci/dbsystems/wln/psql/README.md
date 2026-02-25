# PostgreSQL Hot/Cold Lab — OCI (Terraform)

Módulo Terraform que provisiona na **Oracle Cloud (OCI)** um ambiente completo para PostgreSQL em modelo **HOT/COLD**: compartment, rede (VCN, subnets, NSGs), DB Systems PostgreSQL (HOT e opcionalmente COLD), instância OpenVPN para acesso privado ao banco e bucket Object Storage para archive de billing.

---

## Índice

1. [Visão geral](#1-visão-geral)
2. [O que é criado](#2-o-que-é-criado)
3. [Pré-requisitos](#3-pré-requisitos)
4. [Estrutura dos arquivos](#4-estrutura-dos-arquivos)
5. [Variáveis e `terraform.tfvars`](#5-variáveis-e-terraformtfvars)
6. [Como executar](#6-como-executar)
7. [Um ou dois bancos (HOT / COLD)](#7-um-ou-dois-bancos-hot--cold)
8. [Bucket Object Storage (billing archive)](#8-bucket-object-storage-billing-archive)
9. [Outputs](#9-outputs)
10. [Pipeline Archive/Restore (GitHub Actions)](#10-pipeline-archiverestore-github-actions)
11. [Destruir o ambiente](#11-destruir-o-ambiente)

---

## 1. Visão geral

- **Objetivo:** ambiente de lab/produção com PostgreSQL na OCI, rede isolada e acesso ao banco apenas via VPN.
- **HOT:** DB System principal (produção).
- **COLD:** DB System opcional para archive; pode ser criado depois alterando uma variável.
- **OpenVPN:** instância com IP público para você conectar à VCN e acessar o PostgreSQL por IP privado.
- **Bucket:** Object Storage para o pipeline de arquivar/restaurar dados de billing (COPY ↔ CSV ↔ bucket).

---

## 2. O que é criado

| Recurso | Descrição |
|--------|------------|
| **Compartment** | `psql_hot_cold_lab` (ou uso de `compartment_id` existente) |
| **VCN** | Uma VCN com subnets para DB e VPN |
| **Subnet DB** | Subnet privada onde ficam os DB Systems (sem IP público) |
| **Subnet VPN** | Subnet com rota para Internet Gateway; instância OpenVPN com IP público |
| **NSGs** | Regras de firewall para PostgreSQL e OpenVPN |
| **PostgreSQL Configuration** | Configuração compartilhada (versão, shape) |
| **DB System HOT** | PostgreSQL principal (ex.: `pg-hot-prod`) |
| **DB System COLD** | Opcional; para archive (ex.: `pg-cold-archive`) |
| **Instância OpenVPN** | Ubuntu com OpenVPN; acesso ao DB apenas via túnel VPN |
| **Bucket OCI** | Object Storage para archive de billing (ex.: `navita-billing-archive`) |

---

## 3. Pré-requisitos

- **Terraform** compatível com o provider OCI (recomendado ≥ 1.x).
- **OCI CLI** configurado (ex.: `~/.oci/config`) com perfil usado em `oci_config_profile`.
- **Permissões OCI:** criar compartment, VCN, subnet, NSG, DB System (PostgreSQL), Compute, Object Storage.
- **Chaves SSH:** caminhos em `ssh_public_key_path` e (opcional) `ssh_private_key_path` para a instância OpenVPN.
- **Imagem Ubuntu:** `image_id` válido na região (ex.: São Paulo).

---

## 4. Estrutura dos arquivos

```
psql/
├── README.md           # Este arquivo
├── main.tf             # Provider OCI e local compartment_id
├── variables.tf         # Declaração de todas as variáveis
├── terraform.tfvars    # Valores (não versionar senhas em produção)
├── compartment.tf      # Compartment psql_hot_cold_lab
├── network.tf          # VCN, subnets, NSGs, security lists
├── psql_conf.tf        # Configuração PostgreSQL (oci_psql_configuration)
├── psql.tf             # DB Systems HOT e COLD (oci_psql_db_system)
├── instance_ovpn.tf    # Instância OpenVPN
├── bucket.tf           # Bucket Object Storage (billing archive)
├── outputs.tf          # Outputs (IDs, IPs, bucket, etc.)
└── scripts/            # Scripts de bootstrap (ex.: OpenVPN)
```

---

## 5. Variáveis e `terraform.tfvars`

Todas as entradas são controladas por variáveis; os valores práticos ficam em **`terraform.tfvars`**.

### 5.1 Provider e compartment

| Variável | Uso |
|----------|-----|
| `oci_region` | Região OCI (ex.: `sa-saopaulo-1`) |
| `oci_config_profile` | Perfil em `~/.oci/config` |
| `parent_compartment_id` | OCID do compartment pai onde o lab será criado |
| `compartment_id` | Opcional; se definido, não cria novo compartment e usa este |

### 5.2 DB System HOT

| Variável | Exemplo | Descrição |
|----------|---------|-----------|
| `db_system_display_name` | `pg-hot-prod` | Nome do DB System principal |
| `db_system_description` | `DBSystem HOT - produção` | Descrição |
| `db_version` | `14` | Versão do PostgreSQL |
| `instance_count` | `1` | Número de instâncias |
| `instance_memory_size_in_gbs` | `16` | Memória (GB) por instância |
| `instance_ocpu_count` | `1` | OCPUs por instância |
| `db_system_shape` | `PostgreSQL.VM.Standard.E4.Flex` | Shape do DB System |
| `primary_db_endpoint_private_ip` | `10.0.10.10` | IP privado do endpoint (dentro da subnet DB) |
| `availability_domain` | `YCyV:SA-SAOPAULO-1-AD-1` | AD onde criar o DB System |
| Backup, maintenance, storage | Várias | Backup, janela de manutenção, IOPS, etc. |

### 5.3 DB System COLD (opcional)

| Variável | Uso |
|----------|-----|
| **`create_cold_db_system`** | `false` = aplica só 1 banco (HOT); `true` = cria também o COLD |
| `cold_db_system_display_name` | Nome do DB COLD (ex.: `pg-cold-archive`) |
| `cold_primary_db_endpoint_private_ip` | IP privado do COLD (ex.: `10.0.10.11`) |
| Demais `cold_*` | Overrides de backup, memória, OCPU, etc. |

### 5.4 Rede

| Variável | Exemplo | Descrição |
|----------|---------|-----------|
| `vcn_cidr_block` | `10.0.0.0/16` | CIDR da VCN |
| `subnet_cidr_block` | `10.0.10.0/24` | Subnet do PostgreSQL |
| `vpn_subnet_cidr` | `10.0.20.0/24` | Subnet da instância OpenVPN |

### 5.5 Credenciais do banco

| Variável | Uso |
|----------|-----|
| `db_username` | Usuário admin do PostgreSQL |
| `db_password` | Senha (preferir Vault/secret em produção) |
| `db_password_secret_id` | Opcional; OCID do secret no OCI Vault |

### 5.6 OpenVPN

| Variável | Uso |
|----------|-----|
| `ssh_public_key_path` | Caminho da chave SSH pública para a instância |
| `image_id` | OCID da imagem Ubuntu na região |
| `instance_display_name` | Nome da instância (ex.: `openvpn-psql-lab`) |
| `instance_shape`, `instance_memory_gb`, `instance_ocpus` | Shape da VM |
| `db_subnet_cidr`, `openvpn_port` | Usados no script de instalação do OpenVPN |

### 5.7 Bucket (billing archive)

| Variável | Uso |
|----------|-----|
| `bucket_name` | Nome do bucket (ex.: `navita-billing-archive`) |
| `bucket_namespace` | Namespace do Object Storage do tenancy (ex.: saída de `oci os namespace get`) |

---

## 6. Como executar

```bash
cd terraform/oci/dbsystems/wln/psql
terraform init
terraform plan   # revisar o que será criado
terraform apply  # confirmar com yes
```

- Ajuste **`terraform.tfvars`** antes (região, compartment pai, IPs, senha, namespace do bucket, etc.).
- Em produção, não versionar `terraform.tfvars` com senhas; use variáveis de ambiente ou backend seguro.

---

## 7. Um ou dois bancos (HOT / COLD)

Por padrão o módulo está configurado para criar **apenas 1 banco** (o DB System HOT), para acelerar o apply e reduzir custo no lab.

- **Apenas 1 banco (HOT):**  
  Em `terraform.tfvars`:
  ```hcl
  create_cold_db_system = false
  ```
  O apply cria só o HOT (ex.: `pg-hot-prod`).

- **Dois bancos (HOT + COLD):**  
  Altere para:
  ```hcl
  create_cold_db_system = true
  ```
  E preencha os `cold_*` (IP do COLD, backup, etc.). Em seguida:
  ```bash
  terraform plan && terraform apply
  ```
  O COLD será criado na próxima aplicação.

---

## 8. Bucket Object Storage (billing archive)

O arquivo **`bucket.tf`** cria um bucket OCI usado pelo pipeline de **arquivar/restaurar** dados de billing (tabelas `bill` e `bill_item`).

- **Variáveis:** `bucket_name` e `bucket_namespace` (obrigatório).
- **Namespace:** obtenha com `oci os namespace get` (com OCI CLI configurado) e coloque em `bucket_namespace` no `terraform.tfvars`.
- **Configuração do bucket:** acesso privado (`NoPublicAccess`), tier Standard, versioning desabilitado. Ajustes podem ser feitos em `bucket.tf`.

---

## 9. Outputs

Após o `apply`, use `terraform output` para obter:

| Output | Descrição |
|--------|-----------|
| `compartment_id` | OCID do compartment usado |
| `vcn_id`, `subnet_id` | Rede do PostgreSQL |
| `psql_configuration_id`, `db_system_id` | Configuração e DB System HOT |
| `db_system_display_name`, `state` | Nome e estado do DB System |
| `primary_endpoint_private_ip` | IP privado do endpoint do banco |
| `vpn_public_ip` | IP público da instância OpenVPN (conectar ao VPN) |
| `ssh_connect` | Comando SSH sugerido para acessar a VPN |
| `bucket_name`, `bucket_namespace` | Nome e namespace do bucket de billing |

Exemplo:
```bash
terraform output vpn_public_ip
terraform output ssh_connect
```

---

## 10. Pipeline Archive/Restore (GitHub Actions)

O workflow **Archive/Restore billing data** (`.github/workflows/pipeline-archive-restore-billing.yaml`) permite:

- **Arquivar:** exportar `bill` e `bill_item` (por `company_id` e ano) via `COPY` para CSV → enviar ao bucket OCI → remover do banco.
- **Restaurar:** baixar do bucket → `COPY FROM` para o banco.

Parâmetros do workflow:

- `ambiente`: itau / all / vivo / telefonica (mapeia secrets de DB e prefixo no bucket).
- `company_id`, `year`: recorte dos dados.
- `acao`: arquivar ou restaurar.

O nome do bucket usado no workflow deve ser o mesmo configurado aqui (ex.: `navita-billing-archive`). Configure os secrets de conexão PostgreSQL e OCI no repositório conforme o README/comentários do workflow.

---

## 11. Destruir o ambiente

Para destruir todos os recursos criados por este módulo:

```bash
cd terraform/oci/dbsystems/wln/psql
terraform destroy
```

Confirme quando solicitado. A ordem de destruição é gerenciada pelo Terraform (ex.: instância VPN, DB Systems, subnets, VCN, compartment). Em alguns casos, pode ser necessário repetir o `destroy` ou limpar recursos dependentes manualmente na OCI antes de destruir o compartment.
