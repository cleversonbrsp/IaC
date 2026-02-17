# 🎮 Servidor DayZ na Oracle Cloud Infrastructure (OCI)

Infraestrutura como Código (IaC) usando Terraform para provisionar um servidor DayZ completo na OCI com Ubuntu 2025.07.23-0.

---

## 📑 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Configuração Inicial](#-configuração-inicial)
- [Checklist Pré-Deploy](#-checklist-pré-deploy)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Deploy Passo a Passo](#-deploy-passo-a-passo)
- [Pós-Deploy](#-pós-deploy)
  - [Configuração Manual Passo a Passo](#configuração-manual-passo-a-passo)
  - [Configurar Mods](#63-configurar-mods-se-seu-servidor-usa-mods)
- [Manter o Servidor Rodando 24/7](#-manter-o-servidor-rodando-247)
- [Gerenciamento do Servidor](#-gerenciamento-do-servidor)
  - [Acesso via SFTP/FTP](#acesso-via-sftppftp-gerenciar-arquivos-com-cliente-gráfico)
  - [Comandos Úteis](#comandos-úteis)
- [Troubleshooting](#-troubleshooting)
- [Segurança](#-segurança)
- [Custos](#-custos)
- [FAQ](#-faq)
- [Referências](#-referências)

---

## 🎯 Visão Geral

Este projeto provisiona automaticamente uma infraestrutura completa na OCI para hospedar um servidor DayZ, incluindo:

- ✅ **Instância Compute**: VM.Standard.E4.Flex com 2 OCPUs e 16GB RAM
- ✅ **Imagem**: Ubuntu 2025.07.23-0
- ✅ **Rede**: VCN completa com Internet Gateway, Subnet pública e Security Lists
- ✅ **Servidor DayZ**: **Instalação AUTOMÁTICA** via user-data.sh (baseado em https://community.bistudio.com/wiki/DayZ:Hosting_a_Linux_Server)
- ✅ **Segurança**: Firewall (UFW), Fail2ban, e regras específicas para DayZ
- ✅ **Otimizações**: Configurações de rede para melhor performance em jogos
- ⚠️ **Regra Temporária**: Security List permissiva (0.0.0.0/0, All Protocols) para testes - **REMOVER EM PRODUÇÃO**

### Especificações Técnicas

| Componente | Especificação |
|------------|---------------|
| **Shape** | VM.Standard.E4.Flex (x86_64) |
| **OCPUs** | 2 |
| **RAM** | 16GB |
| **Sistema Operacional** | Ubuntu 24.04 (Build 2025.07.23-0) |
| **Capacidade** | 10-20 jogadores simultâneos |
| **Porta Principal** | 2302 TCP/UDP |
| **Portas Auxiliares** | 2303-2305 UDP, 2306 UDP |
| **Steam Query** | 27016 UDP |
| **SSH** | 22 TCP |
| **Instalação** | **AUTOMÁTICA** via user-data.sh |

---

## 🏗️ Arquitetura

### Diagrama de Componentes

```
┌─────────────────────────────────────────┐
│         Oracle Cloud Infrastructure     │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │     Compartment: dayz-server      │  │
│  │                                   │  │
│  │  ┌────────────────────────────┐  │  │
│  │  │   VCN: dayz-vcn            │  │  │
│  │  │   192.168.0.0/16           │  │  │
│  │  │                            │  │  │
│  │  │  ┌──────────────────────┐  │  │  │
│  │  │  │  Subnet Pública      │  │  │  │
│  │  │  │  192.168.1.0/24     │  │  │  │
│  │  │  │                      │  │  │  │
│  │  │  │  ┌────────────────┐  │  │  │
│  │  │  │  │ DayZ Server    │  │  │  │
│  │  │  │  │ 2 OCPUs        │  │  │  │
│  │  │  │  │ 16GB RAM       │  │  │  │
│  │  │  │  │ Ubuntu 2025    │  │  │  │
│  │  │  │  └────────────────┘  │  │  │
│  │  │  └──────────────────────┘  │  │  │
│  │  │                            │  │  │
│  │  │  ┌──────────────────────┐  │  │  │
│  │  │  │ Internet Gateway     │  │  │  │
│  │  │  └──────────────────────┘  │  │  │
│  │  │                            │  │  │
│  │  │  ┌──────────────────────┐  │  │  │
│  │  │  │ Security List        │  │  │  │
│  │  │  │ - SSH (22)           │  │  │  │
│  │  │  │ - DayZ (2302)        │  │  │  │
│  │  │  │ - DayZ (2303-2305)   │  │  │  │
│  │  │  └──────────────────────┘  │  │  │
│  │  └────────────────────────────┘  │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Fluxo de Dados

#### Tráfego de Jogo (DayZ)
```
Jogador (Internet)
    ↓
Internet Gateway (OCI)
    ↓
Security List (Regras de Firewall)
    ↓
Subnet Pública
    ↓
VNIC da Instância
    ↓
UFW (Firewall do Sistema)
    ↓
Servidor DayZ (Porta 2302)
```

#### Tráfego Administrativo (SSH)
```
Administrador (Internet)
    ↓
Internet Gateway (OCI)
    ↓
Security List (Porta 22)
    ↓
Subnet Pública
    ↓
VNIC da Instância
    ↓
UFW (Porta 22)
    ↓
SSH Daemon
    ↓
Usuário 'dayz'
```

### Portas e Protocolos

| Porta | Protocolo | Direção | Propósito |
|-------|-----------|---------|-----------|
| 22 | TCP | Ingress | SSH - Administração |
| 2302 | TCP | Ingress | DayZ - Comunicação cliente |
| 2302 | UDP | Ingress | DayZ - Jogo principal |
| 2303-2305 | UDP | Ingress | DayZ - Portas auxiliares |
| 2306 | UDP | Ingress | DayZ - Porta auxiliar adicional |
| 27016 | UDP | Ingress | Steam - Query e comunicação |
| All | All | Egress | Download, atualizações, etc. |

---

## 📦 Pré-requisitos

### 1. Conta OCI e Credenciais

Você precisa ter:
- ✅ Uma conta ativa na Oracle Cloud Infrastructure
- ✅ Permissões para criar recursos (Compute, Network, Identity)
- ✅ API Key configurada

### 2. Configuração do OCI CLI

Configure o perfil `devopsguide` no arquivo `~/.oci/config`:

```ini
[devopsguide]
user=ocid1.user.oc1..aaaaaaa...
fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
tenancy=ocid1.tenancy.oc1..aaaaaaa...
region=sa-saopaulo-1
key_file=~/.oci/devopsguide_private_key.pem
```

**Como obter as credenciais:**
1. Acesse o Console OCI
2. Menu → Identity → Users → Seu usuário
3. API Keys → Add API Key
4. Baixe a chave privada e copie o fingerprint
5. Anote o User OCID e Tenancy OCID

### 3. Ferramentas Necessárias

```bash
# Terraform (versão >= 1.0)
terraform --version

# OCI CLI (opcional, para verificação)
oci --version
```

### 4. Chave SSH

A chave SSH é necessária para acessar a instância após o deploy. Você pode usar uma chave existente ou gerar uma nova.

#### Gerar Nova Chave SSH (Opcional)

Se você não tiver uma chave SSH, gere uma:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/dayz_server_key
```

#### Obter Conteúdo da Chave Pública

Para usar uma chave existente, obtenha o conteúdo da chave pública:

```bash
# Se você tem a chave em ~/.ssh/instance-oci.pub
cat ~/.ssh/instance-oci.pub

# Ou para qualquer outra chave
cat ~/.ssh/id_rsa.pub
# ou
cat ~/.ssh/id_ed25519.pub
```

**Importante**: Copie o conteúdo completo da chave (incluindo `ssh-rsa` ou `ssh-ed25519` no início e o comentário no final).

#### Verificar Chave Privada

Certifique-se de ter a chave privada correspondente:

```bash
# Verificar se a chave privada existe
ls -la ~/.ssh/instance-oci.key

# Verificar permissões (deve ser 600)
chmod 600 ~/.ssh/instance-oci.key
```

**Nota**: A chave privada será usada para acessar a instância após o deploy.

---

## ⚙️ Configuração Inicial

### 1. Clone e Acesse o Diretório

```bash
cd /home/cleverson/Documents/github/crs-repos/IaC/terraform/oci/dayz-server
```

### 2. Configure as Variáveis

Edite o arquivo `terraform.tfvars` com suas informações:

```hcl
# Região OCI
oci_region = "sa-saopaulo-1"

# Availability Domain (formato: REGION-AD-X, SEM prefixo agak:)
oci_ad = "SA-SAOPAULO-1-AD-1"

# Compartment OCID (root tenancy ou sub-compartment)
comp_id = "ocid1.tenancy.oc1..aaaaaaa..."

# Chave SSH pública (conteúdo completo da chave pública)
ssh_instances_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."

# OCID da imagem Ubuntu 2025.07.23-0 (opcional - deixe vazio para busca automática)
ubuntu_image_ocid = ""

# Steam Login (opcional)
# Se vazio (""), usa login anônimo (pode ter limitações)
# Se preenchido, usa login com conta Steam (mais confiável)
steam_username = "thefly72003"  # Deixe vazio para anônimo, ou preencha com seu usuário Steam

# Steam Password (opcional, NÃO RECOMENDADO por segurança)
# ⚠️ ATENÇÃO: Se preenchido, a senha será armazenada em texto plano no user-data!
# Opções:
# 1. Deixe vazio (""): Você precisará autenticar manualmente via SSH na primeira vez (RECOMENDADO)
# 2. Preencha com sua senha: Instalação totalmente automática (mas senha em texto plano - NÃO RECOMENDADO)
# 3. Use login anônimo: Deixe steam_username vazio também
steam_password = ""  # ⚠️ NÃO RECOMENDADO: Deixe vazio e autentique manualmente
```

**Notas**:
- Se `ubuntu_image_ocid` estiver vazio, o Terraform tentará buscar automaticamente a imagem Ubuntu 2025.07.23-0.
- **Steam Login**: 
  - **Opção 1 (Recomendado)**: `steam_username` preenchido + `steam_password` vazio
    - Instalação automática tentará fazer login, mas falhará (precisa de senha/Steam Guard)
    - Após o deploy, você autentica manualmente via SSH uma vez
    - Depois disso, o SteamCMD salva as credenciais e funciona automaticamente
  - **Opção 2 (Automático, mas inseguro)**: `steam_username` + `steam_password` preenchidos
    - Instalação totalmente automática
    - ⚠️ Senha armazenada em texto plano no user-data (visível nos logs)
  - **Opção 3 (Mais simples)**: Ambos vazios = login anônimo
    - Pode funcionar, mas pode ter limitações

### 3. Inicialize o Terraform

```bash
# Se houver erro de versão, atualize o lock file
terraform init -upgrade

# Verifique o plano
terraform plan
```

**⚠️ Sobre o erro de versão**: Se você ver um erro como:
```
locked provider registry.terraform.io/oracle/oci 7.0.0 does not match 
configured version constraint ~> 7.30.0
```

Execute:
```bash
terraform init -upgrade
```

Isso atualizará o arquivo `.terraform.lock.hcl` para usar a versão correta do provider.

---

## ✅ Checklist Pré-Deploy

Use este checklist antes de executar `terraform apply`:

### 🔐 Autenticação OCI

- [ ] Perfil `devopsguide` configurado em `~/.oci/config`
- [ ] Chave privada existe e tem permissões corretas (`chmod 600`)
- [ ] Teste de autenticação: `oci iam region list --profile devopsguide`

### 📝 Variáveis Configuradas

Verifique se `terraform.tfvars` tem:

- [ ] `oci_region` - Região OCI (ex: `sa-saopaulo-1`)
- [ ] `oci_ad` - Availability Domain (ex: `SA-SAOPAULO-1-AD-1` - SEM prefixo agak:)
- [ ] `comp_id` - OCID do compartment/tenancy
- [ ] `ssh_instances_key` - Chave SSH pública completa (conteúdo completo da chave)
- [ ] `ubuntu_image_ocid` - Opcional (deixe vazio ou comentado para busca automática)

**Verificar chave SSH**:
```bash
# Verificar se a chave pública está correta
cat ~/.ssh/instance-oci.pub

# Verificar se a chave privada existe e tem permissões corretas
ls -la ~/.ssh/instance-oci.key
chmod 600 ~/.ssh/instance-oci.key  # Se necessário
```

### 🔍 Validações

Execute estes comandos:

```bash
# 1. Validar sintaxe Terraform
terraform validate
# Deve retornar: Success! The configuration is valid.

# 2. Formatar código (opcional)
terraform fmt

# 3. Verificar plano (SEM aplicar)
terraform plan
# Revise cuidadosamente o que será criado
```

### ⚠️ Verificações Importantes

- [ ] Tem permissões para criar recursos no compartment especificado?
- [ ] Tem quota suficiente para 2 OCPUs e 16GB RAM?
- [ ] A região especificada tem disponibilidade para VM.Standard.A1.Flex?
- [ ] Chave SSH está correta e você tem a chave privada correspondente?

### 🚀 Pronto para Deploy?

Se todos os itens acima estão ✅, você pode executar:

```bash
terraform apply
```

**Tempo estimado**: 5-10 minutos para criar toda a infraestrutura.

---

## 📁 Estrutura do Projeto

```
dayz-server/
├── terraform/             # Arquivos Terraform
│   ├── main.tf            # Configuração do provider Terraform
│   ├── variables.tf       # Definição de todas as variáveis
│   ├── terraform.tfvars   # Valores das variáveis (não versionar!)
│   ├── network.tf         # VCN, Subnet, Security Lists, Internet Gateway
│   ├── instances.tf       # Instância Compute com configuração
│   └── outputs.tf         # Outputs do Terraform (IPs, comandos, etc.)
├── scripts/               # Scripts de automação
│   ├── user-data.sh       # Script de inicialização do servidor (executado na instância)
│   └── validar_deploy.sh  # Script para validar o deploy
├── docs/                  # Documentação adicional
│   ├── COMANDOS_SERVIDOR.md
│   └── COMANDOS_VALIDACAO.md
├── README.md              # Esta documentação (principal)
└── terraform.tfstate*     # Estado do Terraform (gerado automaticamente)
```

### Descrição dos Arquivos

#### `terraform/main.tf`
- Configuração do provider OCI
- Usa o perfil `devopsguide` do arquivo `~/.oci/config`
- Define a versão do provider OCI (~> 7.30.0)

#### `terraform/variables.tf`
- Define todas as variáveis usadas no projeto
- Inclui descrições e valores padrão

#### `terraform/network.tf`
- **VCN**: Virtual Cloud Network (192.168.0.0/16)
- **Internet Gateway**: Conectividade com a internet
- **Route Table**: Roteamento para o Internet Gateway
- **Security List**: Regras de firewall específicas para DayZ
  - SSH (22/TCP)
  - DayZ porta principal (2302/TCP e UDP)
  - DayZ portas adicionais (2303-2305/UDP, 2306/UDP)
  - Steam query port (27016/UDP)
  - ICMP para troubleshooting

#### `terraform/instances.tf`
- Cria a instância Compute
- Configura shape (2 OCPUs, 16GB RAM)
- Anexa à subnet pública
- Referencia `scripts/user-data.sh` para inicialização automática
- Configura user-data para instalação automática

#### `user-data.sh`
Script de inicialização que executa **automaticamente** na primeira inicialização da instância:

**O que é executado automaticamente:**
1. Atualiza o sistema (apt update/upgrade)
2. Instala dependências (SteamCMD, bibliotecas, ferramentas)
3. Cria usuário `dayz` com sudo
4. Configura firewall (UFW) - **temporariamente permissivo para testes**
5. Instala e configura Fail2ban
6. **Instala AUTOMATICAMENTE o servidor DayZ via SteamCMD** (baseado em https://community.bistudio.com/wiki/DayZ:Hosting_a_Linux_Server)
7. Cria service systemd para gerenciar o servidor
8. **Inicia automaticamente o servidor após instalação**
9. Aplica otimizações de rede para jogos

**⚠️ IMPORTANTE - Regras Temporárias:**
- Security List com regra permissiva (0.0.0.0/0, All Protocols) - **REMOVER EM PRODUÇÃO**
- UFW configurado como `allow incoming` - **MUDAR PARA 'deny' EM PRODUÇÃO**

#### `terraform/outputs.tf`
- IP público e privado da instância
- Comando SSH pronto para uso
- Informações sobre portas e comandos do servidor

#### `scripts/user-data.sh`
- Script executado automaticamente na inicialização da instância
- Instala dependências (SteamCMD, bibliotecas, ferramentas)
- Cria usuário `dayz` e configura ambiente
- Configura firewall e segurança
- **Instala AUTOMATICAMENTE o servidor DayZ via SteamCMD**
- **Inicia automaticamente o servidor após instalação**

#### `scripts/validar_deploy.sh`
- Script para validar o deploy do servidor
- Verifica conectividade SSH
- Verifica se o servidor DayZ está rodando
- Valida configurações e portas

#### `docs/`
- Documentação adicional sobre comandos e validação
- Veja `docs/README.md` para mais informações

---

## 🚀 Deploy Passo a Passo

**⚠️ IMPORTANTE**: Todos os comandos Terraform devem ser executados dentro da pasta `terraform/`:

```bash
cd terraform
```

### Passo 1: Inicializar o Terraform

```bash
cd terraform
terraform init -upgrade
```

### Passo 2: Planejar a Infraestrutura

```bash
cd terraform
terraform plan
```

Revise as mudanças que serão aplicadas. Você verá:
- VCN `dayz-vcn` (192.168.0.0/16)
- Internet Gateway
- Route Table
- Security List com regras DayZ
- Subnet pública (192.168.1.0/24)
- Instância Compute (2 OCPUs, 16GB RAM)

### Passo 3: Aplicar a Infraestrutura

```bash
cd terraform
terraform apply
```

Confirme digitando `yes` quando solicitado.

**Tempo estimado**: 5-10 minutos

**O que acontece**:
1. Terraform cria os recursos na ordem de dependência
2. A instância é criada com user-data
3. O script user-data.sh executa **automaticamente** na primeira inicialização (2-3 minutos)
   - ✅ Instala dependências (SteamCMD, bibliotecas, ferramentas)
   - ✅ Cria usuário `dayz` e configura ambiente
   - ✅ Configura firewall e segurança (temporariamente permissivo)
   - ✅ **Instala AUTOMATICAMENTE o servidor DayZ via SteamCMD**
   - ✅ **Inicia automaticamente o servidor após instalação**
4. Servidor DayZ fica pronto e rodando automaticamente (aguarde 10-15 minutos para instalação completa)

### Passo 4: Verificar Outputs

```bash
cd terraform

# Ver todos os outputs
terraform output

# Ver IP público
terraform output instance_public_ip

# Ver comando SSH (usa usuário 'ubuntu' inicialmente)
terraform output ssh_connection
```

**Nota sobre usuários**:
- **Usuário inicial**: `ubuntu` (usuário padrão da imagem Ubuntu)
- **Usuário DayZ**: `dayz` (criado pelo user-data, use `sudo su - dayz` após acessar)

---

## 📋 Pós-Deploy

### 1. Acessar o Servidor

**⚠️ Importante**: O usuário padrão da imagem Ubuntu é `ubuntu`, não `dayz`. O usuário `dayz` é criado pelo user-data, mas você acessa primeiro como `ubuntu`.

```bash
# Obter o IP público
terraform output instance_public_ip

# Acessar usando a chave privada
ssh -i ~/.ssh/instance-oci.key ubuntu@<IP_PUBLICO>

# Ou se você configurou o ~/.ssh/config (veja abaixo)
ssh dayz-server
```

#### Configuração Opcional do SSH Config

Para facilitar o acesso, você pode configurar o arquivo `~/.ssh/config`:

```bash
# Editar ~/.ssh/config
nano ~/.ssh/config

# Adicionar:
Host dayz-server
    HostName <IP_PUBLICO>
    User ubuntu
    IdentityFile ~/.ssh/instance-oci.key
    StrictHostKeyChecking no
```

Depois você pode acessar simplesmente com:
```bash
ssh dayz-server
```

#### Trocar para Usuário DayZ

Após acessar como `ubuntu`, você pode trocar para o usuário `dayz`:

```bash
# Acessar como usuário dayz
sudo su - dayz

# Ou usar sudo para executar comandos como dayz
sudo -u dayz bash
```

### 2. Verificar Instalação Inicial

**⚠️ Importante**: Aguarde 10-15 minutos após o `terraform apply` (executado em `terraform/`) para:
1. User-data executar completamente (2-3 minutos)
2. **Instalação automática do DayZ Server via SteamCMD** (5-10 minutos)
3. Servidor iniciar automaticamente (1-2 minutos)

```bash
# Ver log do user-data (aguarde até ver "Configuração concluída")
sudo cat /var/log/user-data.log

# Verificar se usuário dayz existe
id dayz

# Verificar se SteamCMD está instalado
ls -la /opt/steamcmd/steamcmd.sh

# Verificar firewall
sudo ufw status

# Verificar se scripts foram criados
ls -la /home/dayz/*.sh
```

### 3. Verificar o que já foi feito

Primeiro, vamos verificar o que o user-data já configurou:

```bash
# Verificar se o usuário dayz existe
id dayz

# Verificar se SteamCMD está instalado
ls -la /opt/steamcmd/steamcmd.sh

# Verificar se os diretórios foram criados
ls -la /home/dayz/

# Verificar se os scripts foram criados
ls -la /home/dayz/*.sh

# Verificar firewall
sudo ufw status
```

**O que já está pronto:**
- ✅ Sistema atualizado
- ✅ Dependências instaladas (SteamCMD, bibliotecas, etc.)
- ✅ Usuário `dayz` criado
- ✅ Firewall configurado (temporariamente permissivo para testes)
- ✅ Diretórios criados (`/home/dayz/dayzserver`)
- ✅ **Servidor DayZ sendo instalado AUTOMATICAMENTE via SteamCMD** (aguarde 10-15 minutos)
- ✅ **Servidor iniciará automaticamente após instalação**

**⚠️ IMPORTANTE - Regras Temporárias de Segurança:**
- Security List com regra permissiva (0.0.0.0/0, All Protocols) - **REMOVER EM PRODUÇÃO**
- UFW configurado como `allow incoming` - **MUDAR PARA 'deny' EM PRODUÇÃO**

### 4. Verificar Instalação Automática do DayZ

**✅ A instalação do DayZ Server é AUTOMÁTICA via user-data.sh!**

Aguarde 10-15 minutos após o `terraform apply` (executado em `terraform/`) e verifique:

```bash
# Verificar se o servidor DayZ foi instalado
ls -la /home/dayz/dayzserver/DayZServer_x64
# ou
ls -la /home/dayz/dayzserver/DayZServer

# Verificar se o servidor está rodando
sudo systemctl status dayz-server

# Ver logs da instalação
sudo journalctl -u dayz-server -f
```

**Se a instalação automática não funcionar** (especialmente se você usou `steam_username` sem `steam_password`), você precisará autenticar manualmente. Veja a seção abaixo.

### 4.1. Autenticação Manual do Steam (se necessário)

**Quando é necessário:**
- Você configurou `steam_username` mas deixou `steam_password` vazio (recomendado)
- A instalação automática falhou porque precisa de senha/Steam Guard

**Como fazer:**

1. **Acesse o servidor via SSH:**
   ```bash
   ssh -i ~/.ssh/instance-oci.key ubuntu@<IP_PUBLICO>
   ```

2. **Troque para o usuário dayz:**
   ```bash
   sudo su - dayz
   ```

3. **Execute o SteamCMD manualmente:**
   ```bash
   cd /opt/steamcmd
   ./steamcmd.sh +login thefly72003 +force_install_dir /home/dayz/dayzserver +app_update 223350 validate +quit
   ```

4. **Quando solicitado:**
   - Digite sua senha do Steam (não aparecerá na tela)
   - Se tiver Steam Guard, você receberá um código por email/app
   - Digite o código quando solicitado

5. **Após instalação bem-sucedida:**
   - O SteamCMD salva suas credenciais automaticamente
   - Próximas atualizações funcionarão automaticamente (sem precisar digitar senha novamente)
   - O servidor DayZ será iniciado automaticamente pelo systemd

**✅ Vantagem**: Você só precisa fazer isso UMA VEZ. Depois disso, o SteamCMD lembra suas credenciais e tudo funciona automaticamente.

**Se a instalação automática não funcionar por outros motivos**, você pode instalar manualmente (veja seção abaixo).

#### Opção A: Login com conta Steam (Recomendado)

Se você tem o DayZ na sua conta Steam ou quer garantir acesso completo:

```bash
# Executar SteamCMD interativamente
cd /opt/steamcmd
./steamcmd.sh

# Dentro do SteamCMD, execute:
Steam> login seu_usuario_steam
# ⚠️ IMPORTANTE: Use o comando "login" seguido do nome de usuário
# Exemplo: login Jo2608
# Depois digite sua senha quando solicitado (ela não aparecerá na tela)
# Se tiver Steam Guard, você receberá um código por email que precisará digitar

# Quando logado com sucesso, você verá:
# "Logged in as: seu_usuario"

# Depois de logado, você pode sair
Steam> quit
```

**⚠️ Erro comum**: Não digite apenas o nome de usuário ou senha diretamente. Sempre use o comando `login` primeiro:
- ❌ Errado: `Steam> Jo2608` ou `Steam> minhasenha`
- ✅ Correto: `Steam> login Jo2608` (depois digite a senha quando solicitado)

**Vantagens do login com conta:**
- ✅ Acesso garantido ao servidor DayZ
- ✅ Pode atualizar sem problemas
- ✅ Funciona mesmo se login anônimo falhar

#### Alternativa: Login direto na linha de comando (Mais fácil)

Se preferir não usar o modo interativo, você pode fazer login diretamente:

```bash
cd /opt/steamcmd

# Este comando pedirá senha e Steam Guard automaticamente
./steamcmd.sh +login seu_usuario +force_install_dir /home/dayz/dayzserver +app_update 223350 validate +quit

# Depois, garantir permissões
sudo chown -R dayz:dayz /home/dayz/dayzserver
chmod +x /home/dayz/dayzserver/DayZServer_x64
```

**Vantagem**: Mais simples, não precisa entrar no modo interativo do SteamCMD.

#### Opção B: Login anônimo (Pode funcionar)

O script `install_dayz.sh` já usa login anônimo. Você pode tentar primeiro:

```bash
# Se funcionar, ótimo! Se não, use login com conta
```

### 5. Instalar o Servidor DayZ (MANUAL - apenas se necessário)

**⚠️ NOTA**: A instalação é AUTOMÁTICA via user-data.sh. Use esta seção apenas se a instalação automática falhar.

#### Método 1: Usando o script preparado (Recomendado)

```bash
# Certifique-se de estar como usuário dayz
sudo su - dayz

# Executar o script de instalação
./install_dayz.sh
```

**O que o script faz:**
- Baixa o servidor DayZ via SteamCMD (login anônimo)
- Valida arquivos
- Configura permissões

**Tempo estimado**: 10-30 minutos (depende da velocidade da internet)

**✅ Após instalação bem-sucedida**, você verá:
```
Success! App '223350' fully installed.
Unloading Steam API...OK
```

**Próximos passos após instalação**:
1. Verificar se os arquivos foram instalados:
   ```bash
   ls -la /home/dayz/dayzserver/
   # Deve mostrar DayZServer_x64 e outros arquivos
   ```

2. Garantir permissões corretas:
   ```bash
   chmod +x /home/dayz/dayzserver/DayZServer_x64
   ```

3. Prosseguir para [Configurar o Servidor DayZ](#6-configurar-o-servidor-dayz)

#### Método 2: Instalação manual via SteamCMD

Se preferir fazer manualmente ou se o script não funcionar:

```bash
cd /opt/steamcmd

# Se você fez login antes, use:
./steamcmd.sh +login seu_usuario +force_install_dir /home/dayz/dayzserver +app_update 223350 validate +quit

# Ou se usar login anônimo:
./steamcmd.sh +login anonymous +force_install_dir /home/dayz/dayzserver +app_update 223350 validate +quit

# Depois, garantir permissões
sudo chown -R dayz:dayz /home/dayz/dayzserver
chmod +x /home/dayz/dayzserver/DayZServer_x64
```

**App ID do DayZ Server**: `223350` ⚠️ **IMPORTANTE**: O App ID correto é `223350` (não `2233500`!)

#### ✅ Verificação Pós-Instalação

Após ver a mensagem `Success! App '223350' fully installed.`, verifique se tudo foi instalado corretamente:

```bash
# Verificar arquivos instalados
ls -la /home/dayz/dayzserver/

# Deve mostrar:
# - DayZServer_x64 (executável principal)
# - serverDZ.cfg (arquivo de configuração)
# - Outros arquivos e diretórios do servidor

# Garantir permissões de execução
chmod +x /home/dayz/dayzserver/DayZServer_x64

# Verificar tamanho (deve ser ~4GB+)
du -sh /home/dayz/dayzserver/
```

**Se tudo estiver OK**, prossiga para configurar o servidor.

### 6. Configurar o Servidor DayZ

#### 6.1. Editar arquivo de configuração principal

```bash
# Como usuário dayz
sudo su - dayz

# Editar o arquivo de configuração
nano /home/dayz/dayzserver/serverDZ.cfg
```

#### 6.2. Configuração Básica Vanilla (Chernarus - Sem Mods)

**Para começar simples**, vamos configurar um servidor DayZ vanilla no mapa Chernarus (padrão):

```bash
# Como usuário dayz
sudo su - dayz

# Editar configuração
nano /home/dayz/dayzserver/serverDZ.cfg
```

**Configuração mínima para servidor vanilla:**

```cpp
hostname = "Meu Servidor DayZ Vanilla";
password = "";  // Vazio = servidor público
passwordAdmin = "MinhaSenhaAdminSegura123!";  // MUDAR ESTA SENHA!
maxPlayers = 60;
verifySignatures = 2;
verifyMods = 0;  // 0 = não verificar mods (vanilla)
disableVoN = 0;
vonCodecQuality = 7;
disable3rdPerson = 0;
disableCrosshair = 0;
serverTimeAcceleration = 1;  // 1 = tempo normal
serverNightTimeAcceleration = 1;
serverTimePersistent = 1;  // 1 = salva o tempo do servidor
instanceId = 1;  // ⚠️ OBRIGATÓRIO: Deve ser um inteiro de 32 bits válido
```

⚠️ **IMPORTANTE**: O parâmetro `instanceId` é **obrigatório** e deve ser um inteiro de 32 bits válido. Sem ele, o servidor falhará com o erro:
```
[ERROR][Server config] :: instanceId parameter is mandatory and must be valid 32-bit integer.
```

**Configurações explicadas para vanilla:**

| Configuração | Valor Vanilla | Descrição |
|--------------|---------------|-----------|
| `hostname` | Nome do servidor | Aparece na lista de servidores |
| `password` | `""` (vazio) | Servidor público (sem senha) |
| `passwordAdmin` | **MUDAR!** | Senha do administrador |
| `maxPlayers` | 60 (ou menos) | Máximo de jogadores simultâneos |
| `verifyMods` | `0` | 0 = não verificar mods (vanilla) |
| `serverTimeAcceleration` | `1` | 1 = tempo normal (24h = 24h real) |
| `serverTimePersistent` | `1` | Salva o tempo do servidor |

**Salvar e sair:**
- `Ctrl + O` para salvar
- `Enter` para confirmar
- `Ctrl + X` para sair

**⚠️ IMPORTANTE**: Mude a `passwordAdmin` para uma senha segura antes de iniciar o servidor!

#### 6.3. Configurações Avançadas (Opcional)

Se quiser personalizar mais, aqui está um exemplo de configuração completa:

```cpp
hostname = "Meu Servidor DayZ OCI";
password = "";  // Senha para entrar (vazio = servidor público)
passwordAdmin = "MinhaSenhaAdminSegura123!";  // MUDAR ESTA SENHA!
maxPlayers = 60;
verifySignatures = 2;
verifyMods = 1;
disableVoN = 0;
vonCodecQuality = 7;
disable3rdPerson = 0;
disableCrosshair = 0;
serverTimeAcceleration = 1;  // 1 = tempo normal
serverNightTimeAcceleration = 1;
serverTimePersistent = 1;  // 1 = salva o tempo do servidor
```

**Configurações explicadas:**

| Configuração | Descrição | Valores Comuns |
|--------------|-----------|----------------|
| `hostname` | Nome do servidor (aparece na lista) | Qualquer string |
| `password` | Senha para jogadores entrarem | "" = público, ou senha |
| `passwordAdmin` | Senha do administrador | **MUDAR!** |
| `maxPlayers` | Máximo de jogadores | 10-100 (depende do hardware) |
| `serverTimeAcceleration` | Velocidade do tempo | 1 = normal, 2 = 2x mais rápido |
| `serverTimePersistent` | Salva o tempo do servidor | 1 = sim, 0 = não |

#### 6.3. Configurar Mods (Se seu servidor usa mods)

**⚠️ Importante**: Se seu servidor possui mods, você precisa baixá-los e configurá-los antes de iniciar o servidor.

##### Passo 1: Obter IDs dos Mods

Você precisa dos **Workshop IDs** dos mods. Existem algumas formas:

**Opção A: Via Steam Workshop (no seu computador com interface gráfica)**
1. Acesse o mod no Steam Workshop
2. A URL será algo como: `https://steamcommunity.com/sharedfiles/filedetails/?id=1234567890`
3. O número após `?id=` é o Workshop ID (ex: `1234567890`)

**Opção B: Via linha de comando (no servidor)**
Se você já tem os IDs dos mods, pode pular este passo.

**Opção C: Verificar no serverDZ.cfg existente**
Se você já tinha um servidor configurado, os IDs podem estar no arquivo de configuração:
```bash
grep -i "mods\|workshop" /home/dayz/dayzserver/serverDZ.cfg
```

##### Passo 2: Baixar Mods via SteamCMD

Para cada mod, você precisa baixá-lo usando o Workshop ID:

```bash
# Como usuário dayz
sudo su - dayz
cd /opt/steamcmd

# Baixar um mod específico (substitua WORKSHOP_ID pelo ID do mod)
# Exemplo: mod com ID 1234567890
./steamcmd.sh +login thefly72003 +workshop_download_item 221100 1234567890 +quit

# Para baixar múltiplos mods, execute o comando para cada um:
./steamcmd.sh +login thefly72003 +workshop_download_item 221100 WORKSHOP_ID_1 +quit
./steamcmd.sh +login thefly72003 +workshop_download_item 221100 WORKSHOP_ID_2 +quit
./steamcmd.sh +login thefly72003 +workshop_download_item 221100 WORKSHOP_ID_3 +quit
```

**Nota**: 
- `221100` é o App ID do DayZ (não do servidor)
- Os mods serão baixados em: `~/Steam/steamapps/workshop/content/221100/`

##### Passo 3: Configurar Mods no serverDZ.cfg

Edite o arquivo de configuração:

```bash
nano /home/dayz/dayzserver/serverDZ.cfg
```

Adicione ou edite a seção de mods:

```cpp
// Exemplo com múltiplos mods
mods[] = {
    "1234567890",  // Workshop ID do mod 1
    "2345678901",  // Workshop ID do mod 2
    "3456789012"   // Workshop ID do mod 3
};

// Ou se já existir, edite a linha existente
// mods[] = {"1234567890", "2345678901"};
```

**Configurações relacionadas a mods**:
```cpp
verifySignatures = 2;  // 2 = verificar assinaturas (recomendado)
verifyMods = 1;        // 1 = verificar mods
```

##### Passo 4: Verificar Mods Instalados

```bash
# Ver mods baixados
ls -la ~/Steam/steamapps/workshop/content/221100/

# Cada diretório é um Workshop ID de um mod
# Exemplo: ~/Steam/steamapps/workshop/content/221100/1234567890/
```

##### Passo 5: Criar Link Simbólico (Se necessário)

Alguns servidores precisam que os mods estejam em um local específico. Se necessário:

```bash
# Criar diretório para mods no servidor
mkdir -p /home/dayz/dayzserver/@mods

# Criar links simbólicos para cada mod
# Exemplo:
ln -s ~/Steam/steamapps/workshop/content/221100/1234567890 /home/dayz/dayzserver/@mods/1234567890
ln -s ~/Steam/steamapps/workshop/content/221100/2345678901 /home/dayz/dayzserver/@mods/2345678901
```

**Nota**: Nem todos os servidores precisam disso. Teste primeiro sem criar os links.

##### Script para Baixar Múltiplos Mods

Se você tem muitos mods, crie um script:

```bash
# Criar script
nano ~/download_mods.sh
```

Conteúdo do script:
```bash
#!/bin/bash
cd /opt/steamcmd

# Lista de Workshop IDs dos seus mods
MODS=(
    "1234567890"
    "2345678901"
    "3456789012"
    # Adicione mais IDs aqui
)

for mod_id in "${MODS[@]}"; do
    echo "Baixando mod $mod_id..."
    ./steamcmd.sh +login thefly72003 +workshop_download_item 221100 "$mod_id" +quit
done

echo "Todos os mods foram baixados!"
```

Tornar executável e executar:
```bash
chmod +x ~/download_mods.sh
~/download_mods.sh
```

#### 6.4. Salvar e sair

No nano:
- `Ctrl + O` para salvar
- `Enter` para confirmar
- `Ctrl + X` para sair

### 7. Iniciar o Servidor DayZ

**Opção 1: Screen (Recomendado)**
```bash
./start_dayz_screen.sh
screen -r dayz-server  # Para ver o servidor
# Ctrl+A, D para sair sem parar o servidor
```

**Opção 2: Systemd Service (⭐ RECOMENDADO - Para servidor 24/7)**

Esta é a melhor opção para manter o servidor rodando 24/7, pois:
- ✅ Inicia automaticamente quando a instância é reiniciada
- ✅ Reinicia automaticamente se o servidor cair
- ✅ Logs centralizados e fáceis de acessar
- ✅ Gerenciamento simples via comandos systemctl

**Iniciar o servidor:**
```bash
sudo systemctl start dayz-server
```

**Habilitar inicialização automática no boot (IMPORTANTE para 24/7):**
```bash
sudo systemctl enable dayz-server
```

**Verificar se está habilitado:**
```bash
sudo systemctl is-enabled dayz-server
# Deve retornar: enabled
```

**Ver status do servidor:**
```bash
sudo systemctl status dayz-server
```

**Ver logs em tempo real:**
```bash
sudo journalctl -u dayz-server -f
```

**Ver últimos logs:**
```bash
sudo journalctl -u dayz-server -n 100
```

**Reiniciar o servidor:**
```bash
sudo systemctl restart dayz-server
```

**Parar o servidor:**
```bash
sudo systemctl stop dayz-server
```

**⚠️ Importante - Configuração do Systemd Service:**

O systemd service está configurado automaticamente pelo `user-data.sh` com:
- ✅ Caminho absoluto do `-config=`: `/home/dayz/dayzserver/serverDZ.cfg`
- ✅ Parâmetros obrigatórios: `-mission=dayzOffline.chernarusplus`, `-do`
- ✅ **BattlEye habilitado** (anti-cheat - necessário para aparecer na lista pública do Steam)
- ✅ `instanceId = 1;` no `serverDZ.cfg` (adicionado automaticamente)
- ✅ Reinício automático configurado (`Restart=on-failure`)

**Se você editar o `serverDZ.cfg` manualmente**, certifique-se de:
1. Incluir o `instanceId = 1;` (obrigatório - sem isso o servidor não inicia!)
2. Manter o caminho absoluto no systemd service
3. Reiniciar o serviço após mudanças: `sudo systemctl restart dayz-server`

**✅ Checklist para Servidor 24/7:**
```bash
# 1. Verificar se o serviço está ativo
sudo systemctl is-active dayz-server
# Deve retornar: active

# 2. Verificar se está habilitado no boot
sudo systemctl is-enabled dayz-server
# Deve retornar: enabled

# 3. Verificar se a porta está aberta
sudo ss -tulpn | grep 2302
# Deve mostrar a porta UDP 2302 em uso

# 4. Verificar se o processo está rodando
ps aux | grep DayZServer | grep -v grep
# Deve mostrar o processo DayZServer_x64
```

Se todos os comandos acima retornarem resultados positivos, seu servidor está configurado para rodar 24/7! 🎉

**Opção 3: Direto**
```bash
./start_dayz.sh
```

### 8. Verificar se está funcionando

#### 8.1. Verificar processos

```bash
# Ver se o servidor está rodando
ps aux | grep DayZServer

# Ver uso de recursos
htop
# Pressione 'q' para sair
```

#### 8.2. Verificar logs

```bash
# Logs do systemd (se usar service)
sudo journalctl -u dayz-server -f

# Logs do DayZ
tail -f /home/dayz/dayzserver/logs/*.log

# Ver últimos logs
ls -lth /home/dayz/dayzserver/logs/ | head -10
```

#### 8.3. Verificar portas

```bash
# Ver portas abertas
sudo netstat -tulpn | grep 2302

# Ou
sudo ss -tulpn | grep 2302
```

#### 8.4. Testar conectividade

Do seu computador local:

```bash
# Testar porta TCP
telnet <IP_PUBLICO> 2302

# Ou com nc
nc -zv <IP_PUBLICO> 2302
```

### 9. Verificar Logs

```bash
# Logs do systemd
sudo journalctl -u dayz-server -f

# Logs do DayZ
tail -f /home/dayz/dayzserver/logs/*.log

# Log do user-data (instalação inicial)
cat /var/log/user-data.log
```

### 10. Conectar ao Servidor no Jogo

**Obter o IP público do servidor:**
```bash
# Via Terraform
terraform output instance_public_ip

# Ou via SSH
curl -s ifconfig.me
```

**No DayZ, conecte ao servidor:**

**Método 1: Buscar na lista de servidores**
1. Abra o DayZ
2. Vá em "Servidores" ou "Multiplayer"
3. Procure pelo nome do servidor (configurado no `serverDZ.cfg` como `hostname`)
4. Clique em "Conectar"

**Método 2: Adicionar servidor manualmente (DIRECT CONNECT)**
1. Abra o DayZ
2. Na tela de servidores, clique no botão **"DIRECT CONNECT"** (canto inferior direito, em vermelho)
3. Digite o IP e porta no formato:
   ```
   137.131.231.155:2302
   ```
   Ou apenas:
   ```
   137.131.231.155
   ```
   (a porta 2302 é padrão)
4. Clique em "Conectar" ou pressione Enter

**Método 3: Adicionar aos Favoritos**
1. Abra o DayZ
2. Vá em "Servidores" → "FAVORITES"
3. Procure por um botão "+" ou "Add Server" / "Adicionar Servidor"
4. Digite:
   - **IP**: `<IP_PUBLICO>` (ex: `137.131.231.155`)
   - **Porta**: `2302`
5. Salve e conecte

**Método 4: Via console do jogo (se disponível)**
```
connect 137.131.231.155:2302
```

**⚠️ IMPORTANTE - Tempo de Inicialização:**
- O servidor DayZ pode levar **3-5 minutos** para carregar completamente o mundo Chernarus
- Durante esse tempo, o servidor pode não aparecer na lista ou não aceitar conexões
- Aguarde alguns minutos após iniciar o servidor antes de tentar conectar
- Verifique os logs para confirmar que o servidor terminou de carregar:
  ```bash
  sudo journalctl -u dayz-server -f
  ```

**Verificar se o servidor está acessível:**
```bash
# Do seu computador local, teste a conectividade:
nc -zv <IP_PUBLICO> 2302
# ou
telnet <IP_PUBLICO> 2302
```

### Checklist Pós-Deploy

- [ ] Instância criada e rodando
- [ ] IP público atribuído
- [ ] SSH acessível
- [ ] User-data executado com sucesso
- [ ] Usuário `dayz` criado
- [ ] SteamCMD instalado
- [ ] **Login no Steam configurado (se necessário)**
- [ ] **Servidor DayZ instalado**
- [ ] **Configuração editada (serverDZ.cfg)**
- [ ] **Senha admin alterada**
- [ ] Firewall configurado
- [ ] Portas abertas (2302, 2303-2305)
- [ ] **Servidor DayZ iniciado**
- [ ] **Logs verificados**
- [ ] **Conexão testada no jogo**

---

## 🔄 Manter o Servidor Rodando 24/7

### Configuração Automática

O servidor está configurado para rodar 24/7 automaticamente através do systemd service. Isso significa:

✅ **Inicialização Automática**: O servidor inicia automaticamente quando a instância é reiniciada  
✅ **Reinício Automático**: Se o servidor cair, o systemd tenta reiniciá-lo automaticamente  
✅ **Logs Centralizados**: Todos os logs estão disponíveis via `journalctl`  
✅ **Gerenciamento Simples**: Comandos simples para iniciar, parar, reiniciar

### Comandos Essenciais para 24/7

```bash
# 1. Iniciar o servidor
sudo systemctl start dayz-server

# 2. Habilitar para iniciar automaticamente no boot (FAÇA ISSO!)
sudo systemctl enable dayz-server

# 3. Verificar se está rodando
sudo systemctl status dayz-server

# 4. Ver logs em tempo real
sudo journalctl -u dayz-server -f

# 5. Verificar se está habilitado no boot
sudo systemctl is-enabled dayz-server
# Deve retornar: enabled
```

### Verificação Rápida de Status

Execute este comando para verificar se tudo está funcionando:

```bash
# Verificar status completo
echo "=== Status do Servidor DayZ ===" && \
echo "Serviço ativo: $(sudo systemctl is-active dayz-server)" && \
echo "Habilitado no boot: $(sudo systemctl is-enabled dayz-server)" && \
echo "Porta 2302: $(sudo ss -tulpn | grep 2302 | head -1 || echo 'Não está em uso')" && \
echo "Processo: $(ps aux | grep DayZServer | grep -v grep | wc -l) processo(s) rodando"
```

### Monitoramento

**Ver logs em tempo real:**
```bash
sudo journalctl -u dayz-server -f
```

**Ver últimos 100 logs:**
```bash
sudo journalctl -u dayz-server -n 100
```

**Ver logs desde hoje:**
```bash
sudo journalctl -u dayz-server --since today
```

**Verificar uso de recursos:**
```bash
# CPU e Memória
htop

# Ou
top -p $(pgrep DayZServer)
```

### Troubleshooting Rápido

**Servidor não está rodando:**
```bash
# Verificar status
sudo systemctl status dayz-server

# Ver logs de erro
sudo journalctl -u dayz-server -n 50 --no-pager

# Tentar iniciar manualmente
sudo systemctl start dayz-server
```

**Servidor parou inesperadamente:**
```bash
# Ver logs para identificar o problema
sudo journalctl -u dayz-server --since "10 minutes ago"

# Reiniciar o servidor
sudo systemctl restart dayz-server
```

**Não consigo conectar / Servidor não aparece na lista:**
```bash
# 1. Verificar se está rodando
sudo systemctl status dayz-server

# 2. Verificar porta
sudo ss -tulpn | grep 2302

# 3. Ver logs em tempo real
sudo journalctl -u dayz-server -f

# 4. Aguardar 3-5 minutos após iniciar (servidor carrega o mundo)
# 5. Usar DIRECT CONNECT com IP: 137.131.231.155:2302
```

**Servidor demora para aparecer na lista:**
- Normal: Servidores podem levar 5-10 minutos para aparecer na lista pública do Steam
- Solução: Use sempre DIRECT CONNECT com o IP
- Verificar: O servidor está conectado ao Steam? Procure por "Connected to Steam" nos logs

**Verificar se há espaço em disco:**
```bash
df -h
```

**Verificar memória disponível:**
```bash
free -h
```

---

## 📝 Configuração Manual Passo a Passo

Esta seção detalha cada passo para configurar o servidor DayZ manualmente após o deploy.

### Estrutura de Arquivos Importantes

```
/home/dayz/
├── dayzserver/              # Diretório principal do servidor
│   ├── DayZServer_x64       # Executável do servidor
│   ├── serverDZ.cfg         # ⚙️ Configuração principal (EDITAR AQUI)
│   ├── basic.cfg             # Configuração básica (opcional)
│   ├── profile/              # Perfis e dados do servidor
│   │   └── (arquivos salvos aqui)
│   └── logs/                 # 📋 Logs do servidor
│       ├── admin.log
│       ├── server.log
│       └── ...
├── install_dayz.sh          # Script de instalação
├── start_dayz.sh            # Script para iniciar diretamente
└── start_dayz_screen.sh     # Script para iniciar em screen

/opt/steamcmd/
└── steamcmd.sh              # SteamCMD para atualizar servidor
```

### Comandos Úteis de Gerenciamento

#### Parar o servidor

```bash
# Se usar screen
screen -r dayz-server
# Ctrl + C

# Se usar systemd
sudo systemctl stop dayz-server

# Se rodando diretamente
# Ctrl + C no terminal
```

#### 🔄 Reiniciar o Servidor

```bash
# Reiniciar via systemd
sudo systemctl restart dayz-server

# Verificar se reiniciou corretamente
sudo systemctl status dayz-server
```

**Quando reiniciar:**
- Após editar `serverDZ.cfg`
- Após atualizar o servidor DayZ
- Se o servidor apresentar problemas
- Após mudanças de configuração

#### Atualizar o servidor DayZ

```bash
# Como usuário dayz
sudo su - dayz
cd /opt/steamcmd

# Se você fez login antes:
./steamcmd.sh +login seu_usuario +force_install_dir /home/dayz/dayzserver +app_update 223350 validate +quit

# Ou com login anônimo:
./steamcmd.sh +login anonymous +force_install_dir /home/dayz/dayzserver +app_update 223350 validate +quit

# Reiniciar o servidor após atualização
sudo systemctl restart dayz-server
```

#### Editar configuração e reiniciar

```bash
# Editar configuração
sudo su - dayz
nano /home/dayz/dayzserver/serverDZ.cfg

# Salvar (Ctrl+O, Enter, Ctrl+X)

# Reiniciar servidor para aplicar mudanças
sudo systemctl restart dayz-server
```

### Troubleshooting Rápido

#### Servidor não inicia

```bash
# Verificar se o executável existe e tem permissão
ls -la /home/dayz/dayzserver/DayZServer_x64
chmod +x /home/dayz/dayzserver/DayZServer_x64

# Verificar logs de erro
tail -50 /home/dayz/dayzserver/logs/*.log

# Verificar se a configuração está correta
cat /home/dayz/dayzserver/serverDZ.cfg
```

#### Erro: "Failed to initialize Steam"

- Verifique se você fez login no SteamCMD
- Tente fazer login novamente: `cd /opt/steamcmd && ./steamcmd.sh +login seu_usuario`

#### Servidor não aparece na lista

- Verifique se as portas estão abertas: `sudo ufw status`
- Verifique se o servidor está rodando: `ps aux | grep DayZServer`
- Verifique o IP público: `cd terraform && terraform output instance_public_ip`
- Aguarde alguns minutos (pode levar tempo para aparecer na lista)

---

## 🎮 Gerenciamento do Servidor

### Acesso via SFTP/FTP (Gerenciar Arquivos com Cliente Gráfico)

**Sim! Você pode usar um cliente FTP/SFTP** para gerenciar arquivos, mods e configurações de forma mais fácil, especialmente se você está acostumado com interfaces gráficas.

#### Opção 1: SFTP (Recomendado - Mais Seguro)

O SFTP já está disponível via SSH. Você não precisa instalar nada adicional!

**Configurar acesso SFTP:**

1. **No servidor**, o SSH já está configurado, então o SFTP funciona automaticamente
2. **No seu computador**, use um cliente SFTP como:
   - **FileZilla** (Windows/Mac/Linux): https://filezilla-project.org/
   - **WinSCP** (Windows): https://winscp.net/
   - **Cyberduck** (Windows/Mac): https://cyberduck.io/
   - **VS Code** com extensão SFTP (se você usa VS Code)

**Configuração no FileZilla/WinSCP:**

```
Protocolo: SFTP - SSH File Transfer Protocol
Host: <IP_PUBLICO> (do terraform output)
Porta: 22
Usuário: ubuntu (ou dayz, se preferir)
Senha: (deixe vazio, use autenticação por chave)
Chave privada: ~/.ssh/instance-oci.key (caminho da sua chave privada)
```

**Importante**: Configure a autenticação por chave SSH (não senha) para maior segurança.

#### Opção 2: Instalar Servidor FTP (VSFTPD) - Opcional

Se você realmente precisa de FTP tradicional (não recomendado por segurança), pode instalar:

```bash
# No servidor
sudo apt update
sudo apt install vsftpd -y

# Configurar (editar /etc/vsftpd.conf)
sudo nano /etc/vsftpd.conf

# Habilitar e iniciar
sudo systemctl enable vsftpd
sudo systemctl start vsftpd

# Abrir porta FTP no firewall (se necessário)
sudo ufw allow 21/tcp
sudo ufw allow 20/tcp
```

**⚠️ Aviso**: FTP não é criptografado. Use SFTP sempre que possível.

#### Diretórios Importantes para Gerenciar via SFTP

Quando conectar via SFTP, você verá a estrutura do servidor. Diretórios importantes:

```
/home/ubuntu/                    # Diretório home do usuário ubuntu
/home/dayz/                       # Diretório home do usuário dayz
├── dayzserver/                  # ⚙️ Diretório principal do servidor DayZ
│   ├── DayZServer_x64          # Executável do servidor
│   ├── serverDZ.cfg             # 📝 Configuração principal (EDITAR AQUI!)
│   ├── basic.cfg                # Configuração básica
│   ├── profile/                 # Dados do servidor (salvos, etc.)
│   └── logs/                    # 📋 Logs do servidor
│       ├── admin.log
│       └── server.log
└── Steam/
    └── steamapps/
        └── workshop/
            └── content/
                └── 221100/      # 📦 Mods do DayZ (Workshop IDs como nomes de pasta)
                    ├── 1234567890/
                    ├── 2345678901/
                    └── ...

/opt/steamcmd/                    # SteamCMD (geralmente só leitura)
```

#### Usando SFTP para Gerenciar Mods

**Vantagens de usar SFTP para mods:**

1. **Upload de mods locais**: Se você tem mods baixados no seu computador, pode fazer upload direto
2. **Gerenciar múltiplos mods**: Mais fácil copiar/mover/renomear pastas de mods
3. **Editar configurações**: Editar `serverDZ.cfg` com seu editor favorito localmente e fazer upload
4. **Backup**: Fazer download de configurações e mods para backup

**Exemplo de workflow:**

1. **Conectar via SFTP** (FileZilla/WinSCP)
2. **Navegar até**: `/home/dayz/Steam/steamapps/workshop/content/221100/`
3. **Upload de mods**: Arraste e solte pastas de mods do seu computador
4. **Editar serverDZ.cfg**: 
   - Baixe o arquivo: `/home/dayz/dayzserver/serverDZ.cfg`
   - Edite localmente com seu editor favorito
   - Faça upload de volta
5. **Reiniciar servidor**: Via SSH (`sudo systemctl restart dayz-server`)

#### Permissões ao Usar SFTP

**Como usuário `ubuntu` (padrão):**
- Você pode acessar `/home/ubuntu/`
- Para acessar `/home/dayz/`, você precisa de sudo ou trocar de usuário

**Solução: Acessar como usuário `dayz`**

1. **Criar chave SSH para usuário dayz** (opcional):
   ```bash
   # No servidor, como root ou ubuntu
   sudo su - dayz
   mkdir -p ~/.ssh
   # Copiar chave pública do ubuntu
   sudo cp /home/ubuntu/.ssh/authorized_keys ~/.ssh/
   sudo chown -R dayz:dayz ~/.ssh
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

2. **Ou usar SFTP como ubuntu e depois trocar de usuário**:
   - Conecte como `ubuntu`
   - Use `sudo` para acessar arquivos do dayz quando necessário

**Recomendação**: Configure acesso SFTP direto como usuário `dayz` para facilitar o gerenciamento.

#### Configuração Rápida de SFTP para Usuário DayZ

```bash
# No servidor, via SSH
sudo su - dayz

# Criar diretório .ssh se não existir
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Copiar chave autorizada do ubuntu (ou adicionar sua chave pública)
sudo cp /home/ubuntu/.ssh/authorized_keys ~/.ssh/authorized_keys
sudo chown dayz:dayz ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Depois disso, você pode conectar via SFTP usando:
- **Usuário**: `dayz`
- **Chave privada**: `~/.ssh/instance-oci.key`
- **Host**: `<IP_PUBLICO>`
- **Porta**: `22`

#### Clientes SFTP Recomendados

| Cliente | Plataforma | Download |
|---------|------------|----------|
| **FileZilla** | Windows/Mac/Linux | https://filezilla-project.org/ |
| **WinSCP** | Windows | https://winscp.net/ |
| **Cyberduck** | Windows/Mac | https://cyberduck.io/ |
| **VS Code SFTP** | Extensão VS Code | Extensão "SFTP" no marketplace |

#### Exemplo de Configuração no FileZilla

1. Abra FileZilla
2. **Arquivo → Gerenciador de Sites → Novo Site**
3. Configure:
   ```
   Protocolo: SFTP - SSH File Transfer Protocol
   Host: <IP_PUBLICO>
   Porta: 22
   Tipo de logon: Chave de arquivo
   Usuário: dayz (ou ubuntu)
   Arquivo de chave: C:\Users\SeuUsuario\.ssh\instance-oci.key (ajuste o caminho)
   ```
4. Clique em **Conectar**

#### Configuração Detalhada no WinSCP (Windows)

**Passo 1: Encontrar sua chave privada**

A chave privada geralmente está em um destes locais:
- `C:\Users\SeuUsuario\.ssh\instance-oci.key`
- `C:\Users\SeuUsuario\.ssh\id_rsa` ou `id_ed25519`
- Onde você salvou quando gerou a chave SSH

**Se você não sabe onde está a chave:**

1. Abra o PowerShell ou CMD no Windows
2. Execute:
   ```powershell
   # Verificar se existe em .ssh
   dir C:\Users\$env:USERNAME\.ssh\
   
   # Ou procurar por arquivos .key ou sem extensão que possam ser chaves
   Get-ChildItem -Path C:\Users\$env:USERNAME -Recurse -Filter "*.key" -ErrorAction SilentlyContinue
   ```

**Passo 2: Converter chave para formato PuTTY (se necessário)**

O WinSCP usa o formato PuTTY (.ppk). Se sua chave está em formato OpenSSH (.key, .pem, sem extensão):

1. **Opção A: Usar PuTTYgen (vem com WinSCP)**
   - Abra **PuTTYgen** (procure no menu Iniciar ou em `C:\Program Files\WinSCP\PuTTYgen.exe`)
   - Clique em **Conversões → Importar chave**
   - Selecione sua chave privada (`instance-oci.key`)
   - Clique em **Salvar chave privada**
   - Salve como `instance-oci.ppk` (formato PuTTY)

2. **Opção B: WinSCP pode converter automaticamente**
   - O WinSCP pode converter automaticamente ao tentar usar a chave OpenSSH

**Passo 3: Configurar conexão no WinSCP**

1. **Abra o WinSCP**

2. **Na tela inicial "Login"**, configure:
   ```
   Protocolo de arquivo: SFTP
   Nome do computador: <IP_PUBLICO> (do terraform output)
   Porta: 22
   Nome de usuário: ubuntu (ou dayz, se configurado)
   Senha: (deixe vazio)
   ```

3. **Clique em "Avançado..."** (ou "Advanced..." se estiver em inglês)

4. **No menu à esquerda**, vá em:
   - **SSH → Autenticação**

5. **Em "Arquivo de chave privada"**, clique em **"..."** (três pontos)

6. **Navegue até sua chave privada:**
   - Se você converteu para .ppk: Selecione `instance-oci.ppk`
   - Se está em formato OpenSSH (.key): Selecione `instance-oci.key` (WinSCP tentará converter)

7. **Clique em "OK"** para fechar a janela Avançado

8. **Clique em "Salvar"** (opcional, para salvar a configuração)

9. **Clique em "Login"** para conectar

**Passo 4: Primeira conexão**

- Na primeira vez, você verá um aviso sobre a chave do servidor
- Clique em **"Sim"** ou **"Sim para todos"** para aceitar

**Passo 5: Navegar pelos arquivos**

Após conectar, você verá:
- **Lado esquerdo**: Seus arquivos locais (Windows)
- **Lado direito**: Arquivos do servidor (Linux)

**Diretórios importantes no servidor:**
```
/home/ubuntu/                    # Diretório home do ubuntu
/home/dayz/                      # Diretório home do dayz
├── dayzserver/                  # Servidor DayZ
│   ├── serverDZ.cfg            # ⚙️ Configuração (EDITAR AQUI)
│   └── logs/                    # Logs
└── Steam/steamapps/workshop/content/221100/  # Mods
```

**Dicas:**
- **Arrastar e soltar**: Funciona para upload/download
- **Duplo clique**: Abre arquivos para edição
- **Botão direito**: Menu de contexto (upload, download, editar, etc.)

#### Troubleshooting WinSCP

**Erro: "Disconnected: No supported authentication methods available"**

- Verifique se o caminho da chave está correto
- Tente converter a chave para .ppk usando PuTTYgen
- Verifique se a chave tem permissões corretas (no Linux, deve ser 600)

**Erro: "Server refused our key"**

- Verifique se você está usando o usuário correto (`ubuntu` ou `dayz`)
- Verifique se a chave pública está no servidor em `~/.ssh/authorized_keys`

**Não consigo encontrar a chave privada**

Se você não tem a chave privada, você precisa:
1. Gerar uma nova chave SSH
2. Adicionar a chave pública ao servidor
3. Usar a chave privada no WinSCP

**Gerar nova chave no Windows (PowerShell):**
```powershell
# Gerar nova chave
ssh-keygen -t rsa -b 4096 -f C:\Users\$env:USERNAME\.ssh\instance-oci.key

# Ver chave pública (para adicionar ao servidor)
cat C:\Users\$env:USERNAME\.ssh\instance-oci.key.pub
```

Depois, adicione a chave pública ao servidor via SSH:
```bash
# No servidor
echo "cole_a_chave_publica_aqui" >> ~/.ssh/authorized_keys
```

#### Dicas de Uso

- **Editar arquivos**: Baixe, edite localmente, faça upload de volta
- **Upload de mods**: Arraste pastas de mods para `/home/dayz/Steam/steamapps/workshop/content/221100/`
- **Backup**: Faça download regular de `serverDZ.cfg` e da pasta `profile/`
- **Logs**: Baixe logs para análise local: `/home/dayz/dayzserver/logs/`

#### Migrar Servidor DayZ do Windows para Linux

Se você já tem um servidor DayZ funcionando no Windows e quer migrar para o servidor Linux:

**⚠️ IMPORTANTE**: O executável do servidor (`DayZServer_x64.exe`) **NÃO precisa ser transferido**. O servidor Linux já tem o executável correto (`DayZServer_x64` sem .exe).

**O que transferir:**

1. **Configuração principal** (`serverDZ.cfg`):
   - **No WinSCP**: Arraste `serverDZ.cfg` do Windows para `/home/dayz/dayzserver/serverDZ.cfg` no Linux
   - **Verificar**: O arquivo deve ter as mesmas configurações, mas pode precisar de ajustes

2. **Mods** (pastas `@NomeDoMod`):
   - **No Windows**: Você tem pastas como `@Banov`, `@CF`, `@VPPAdminTools`
   - **No Linux**: Os mods devem estar em `/home/dayz/Steam/steamapps/workshop/content/221100/`
   - **Opção A - Se os mods vieram do Steam Workshop**:
     - Use os **Workshop IDs** dos mods
     - Baixe via SteamCMD (veja seção [Configurar Mods](#63-configurar-mods-se-seu-servidor-usa-mods))
   - **Opção B - Se são mods locais/customizados**:
     - Crie diretório: `/home/dayz/dayzserver/@mods/` (ou similar)
     - Arraste as pastas `@Banov`, `@CF`, `@VPPAdminTools` para lá
     - **Atenção**: Verifique se os mods são compatíveis com Linux

3. **Arquivos de configuração adicionais**:
   - `ban.txt` → `/home/dayz/dayzserver/ban.txt`
   - `whitelist.txt` → `/home/dayz/dayzserver/whitelist.txt`
   - `dayzsetting.xml` → `/home/dayz/dayzserver/dayzsetting.xml` (se existir)
   - Outros arquivos `.cfg` ou `.txt` de configuração

4. **Perfis e dados do servidor** (se quiser manter o progresso):
   - Pasta `profiles/` → `/home/dayz/dayzserver/profile/`
   - **⚠️ Cuidado**: Isso substituirá os dados existentes

5. **Configurações de BattlEye** (se usar):
   - Pasta `battleye/` → `/home/dayz/dayzserver/battleye/`

**Passo a Passo no WinSCP:**

1. **Conecte ao servidor Linux** (já está conectado ✅)

2. **Navegue até o diretório do servidor no Linux**:
   - No lado direito (servidor), vá para: `/home/dayz/dayzserver/`

3. **No lado esquerdo (Windows)**, navegue até seu servidor DayZ atual

4. **Transferir `serverDZ.cfg`**:
   - Arraste `serverDZ.cfg` do Windows para `/home/dayz/dayzserver/` no Linux
   - **Substituir** quando perguntado

5. **Transferir mods**:
   
   **Se os mods são do Steam Workshop:**
   - Anote os Workshop IDs dos mods (veja seção de mods)
   - Baixe via SteamCMD no servidor Linux
   
   **Se são mods locais:**
   - Crie diretório: `/home/dayz/dayzserver/@mods/` (ou onde preferir)
   - Arraste as pastas `@Banov`, `@CF`, `@VPPAdminTools` para lá
   - **Verifique permissões**: `sudo chown -R dayz:dayz /home/dayz/dayzserver/@mods/`

6. **Transferir outros arquivos**:
   - Arraste `ban.txt`, `whitelist.txt`, etc. para `/home/dayz/dayzserver/`

7. **Ajustar permissões** (via SSH):
   ```bash
   sudo chown -R dayz:dayz /home/dayz/dayzserver/
   ```

8. **Verificar e ajustar `serverDZ.cfg`**:
   - Edite o arquivo no WinSCP (duplo clique)
   - Verifique se os caminhos dos mods estão corretos
   - **No Linux, os mods podem estar em locais diferentes**

**Diferenças Windows vs Linux:**

| Item | Windows | Linux |
|------|---------|-------|
| Executável | `DayZServer_x64.exe` | `DayZServer_x64` (sem .exe) |
| Mods Workshop | `steamapps/workshop/content/221100/` | `~/Steam/steamapps/workshop/content/221100/` |
| Mods locais | `@NomeMod/` na raiz | `@NomeMod/` ou `@mods/@NomeMod/` |
| Caminhos | `C:\...` | `/home/dayz/dayzserver/...` |
| Separador | `\` | `/` |

**Ajustes necessários no `serverDZ.cfg`:**

Após transferir, verifique:

1. **Caminhos de mods** (se usar caminhos absolutos):
   ```cpp
   // Windows (não funciona no Linux)
   mods[] = {"C:\\DayZServer\\@Banov"};
   
   // Linux (correto)
   mods[] = {"1234567890"};  // Workshop ID
   // ou
   mods[] = {"@Banov"};  // Se estiver na raiz do servidor
   ```

2. **Caminhos de arquivos**:
   - Verifique se `ban.txt`, `whitelist.txt` estão no caminho correto
   - No Linux, geralmente na raiz do `dayzserver/`

**Verificar após transferência:**

```bash
# Via SSH, verificar estrutura
sudo su - dayz
cd /home/dayz/dayzserver
ls -la

# Verificar se serverDZ.cfg está correto
cat serverDZ.cfg | grep -i mods

# Verificar permissões
ls -la | grep -E "serverDZ|ban|whitelist"
```

**Próximos passos após transferir:**

1. ✅ Arquivos transferidos
2. ✅ Permissões ajustadas
3. ⏭️ Editar `serverDZ.cfg` se necessário
4. ⏭️ Testar servidor: `sudo systemctl start dayz-server`
5. ⏭️ Verificar logs: `sudo journalctl -u dayz-server -f`

### Comandos Úteis

#### Gerenciamento do Servidor (Systemd)

```bash
# Ver status do servidor
sudo systemctl status dayz-server

# Iniciar servidor
sudo systemctl start dayz-server

# Parar servidor
sudo systemctl stop dayz-server

# Reiniciar servidor
sudo systemctl restart dayz-server

# Habilitar inicialização automática no boot
sudo systemctl enable dayz-server

# Desabilitar inicialização automática
sudo systemctl disable dayz-server

# Verificar se está habilitado
sudo systemctl is-enabled dayz-server

# Verificar se está ativo
sudo systemctl is-active dayz-server
```

#### Monitoramento de Logs

```bash
# Ver logs em tempo real (seguir logs)
sudo journalctl -u dayz-server -f

# Ver logs recentes (últimas 100 linhas)
sudo journalctl -u dayz-server -n 100

# Ver logs sem paginação (útil para scripts)
sudo journalctl -u dayz-server --no-pager

# Ver logs do DayZ (arquivos RPT e ADM)
tail -f /home/dayz/dayzserver/profile/*.RPT
tail -f /home/dayz/dayzserver/profile/*.ADM

# Ver log de erros do DayZ
tail -f /home/dayz/dayzserver/profile/error.log

# Ver logs do sistema
sudo tail -f /var/log/syslog
```

#### Verificação de Status e Recursos

```bash
# Verificar se o processo está rodando
ps aux | grep DayZServer | grep -v grep

# Contar processos do DayZ
ps aux | grep DayZServer | grep -v grep | wc -l

# Ver uso de CPU e memória do processo
ps aux | grep DayZServer | grep -v grep | awk '{print "CPU: " $3 "% | MEM: " $4 "%"}'

# Ver uso geral de recursos do sistema
htop
# ou
top

# Ver uso de memória
free -h

# Ver uso de disco
df -h
```

#### Verificação de Rede e Portas

```bash
# Verificar portas abertas (2302 e 27016)
sudo ss -tulpn | grep -E '2302|27016'

# Verificar porta 2302 especificamente (UDP)
sudo ss -tulpn | grep 2302 | grep udp

# Verificar porta 27016 (Steam Query - UDP)
sudo ss -tulpn | grep 27016 | grep udp

# Verificar todas as portas UDP abertas
sudo ss -tulpn | grep udp

# Verificar todas as portas TCP abertas
sudo ss -tulpn | grep tcp

# Verificar firewall UFW
sudo ufw status verbose

# Verificar regras do firewall
sudo ufw status numbered
```

#### Validação Completa do Servidor

```bash
# Comando completo de validação (executar via SSH)
echo '=== RESUMO FINAL ===' && \
echo '' && \
echo '✅ Serviço: ' && \
sudo systemctl is-active dayz-server && \
echo '✅ Porta 2302: ' && \
sudo ss -tulpn | grep 2302 | grep udp | head -1 && \
echo '✅ Porta 27016: ' && \
sudo ss -tulpn | grep 27016 | grep udp | head -1 && \
echo '✅ Processo: ' && \
ps aux | grep DayZServer | grep -v grep | wc -l && \
echo 'processo(s) rodando' && \
echo '✅ BattlEye: ' && \
sudo journalctl -u dayz-server --no-pager | grep -q 'BattlEye.*Initialized' && \
echo 'Ativo' || echo 'Não encontrado' && \
echo '✅ Steam: ' && \
sudo journalctl -u dayz-server --no-pager | grep -q 'Connected to Steam' && \
echo 'Conectado' || echo 'Não conectado'
```

#### Verificação de Progresso do Carregamento

```bash
# Verificar tempo desde início do servidor
START=$(sudo systemctl show dayz-server -p ActiveEnterTimestamp --value)
NOW=$(date +%s)
START_EPOCH=$(date -d "$START" +%s)
MINUTES=$(( (NOW - START_EPOCH) / 60 ))
echo "Servidor rodando há: $MINUTES minutos"

# Verificar mensagens importantes nos logs (sem warnings)
sudo journalctl -u dayz-server --no-pager | \
  grep -v 'Warning\|RESOURCES\|No components\|No entry\|Trying to access\|DamageSystem\|PerfWarning\|Convex' | \
  tail -20

# Verificar se o mundo foi carregado (procurar em arquivos RPT)
sudo su - dayz -c 'ls -t /home/dayz/dayzserver/profile/*.RPT 2>/dev/null | head -1 | xargs tail -200 | \
  grep -i -E "world.*load|mission.*load|server.*ready|initialized.*complete|ready.*accept|started.*accept|game.*start|map.*load|spawn|object.*load" | \
  tail -10'
```

#### Verificação de Conectividade Steam e BattlEye

```bash
# Verificar se está conectado ao Steam
sudo journalctl -u dayz-server --no-pager | grep -q 'Connected to Steam' && \
  echo '✅ Conectado ao Steam' || echo '❌ Não conectado ao Steam'

# Verificar se BattlEye está ativo
sudo journalctl -u dayz-server --no-pager | grep -q 'BattlEye.*Initialized' && \
  echo '✅ BattlEye Ativo' || echo '❌ BattlEye Não encontrado'

# Ver mensagens do Steam nos logs
sudo journalctl -u dayz-server --no-pager | grep -i steam

# Ver mensagens do BattlEye nos logs
sudo journalctl -u dayz-server --no-pager | grep -i battleye
```

#### Comandos de Diagnóstico Avançado

```bash
# Verificar arquivos do servidor DayZ
ls -la /home/dayz/dayzserver/DayZServer*
ls -la /home/dayz/dayzserver/serverDZ.cfg

# Verificar permissões
ls -la /home/dayz/dayzserver/ | head -20

# Verificar configuração do servidor
cat /home/dayz/dayzserver/serverDZ.cfg

# Verificar último erro do servidor
tail -50 /home/dayz/dayzserver/profile/error.log

# Verificar último arquivo RPT (log completo)
sudo su - dayz -c 'ls -t /home/dayz/dayzserver/profile/*.RPT 2>/dev/null | head -1 | xargs tail -100'

# Verificar user-data executado
sudo cat /var/lib/cloud/instance/user-data.txt

# Verificar logs do cloud-init
sudo cat /var/log/cloud-init-output.log | tail -100
sudo cat /var/log/cloud-init.log | tail -100
```

#### Comandos para Executar Remotamente (via SSH local)

```bash
# Substitua <IP_PUBLICO> pelo IP da sua instância
# Exemplo: ssh -i ~/.ssh/instance-oci.key ubuntu@137.131.154.107 "<comando>"

# Verificar status completo remotamente
ssh -i ~/.ssh/instance-oci.key ubuntu@<IP_PUBLICO> \
  "echo '=== STATUS ===' && \
   sudo systemctl is-active dayz-server && \
   sudo ss -tulpn | grep 2302 | grep udp && \
   ps aux | grep DayZServer | grep -v grep | wc -l"

# Ver logs recentes remotamente
ssh -i ~/.ssh/instance-oci.key ubuntu@<IP_PUBLICO} \
  "sudo journalctl -u dayz-server -n 50 --no-pager"

# Verificar conectividade Steam remotamente
ssh -i ~/.ssh/instance-oci.key ubuntu@<IP_PUBLICO> \
  "sudo journalctl -u dayz-server --no-pager | grep -q 'Connected to Steam' && \
   echo '✅ Conectado' || echo '❌ Não conectado'"
```

### Atualizar Servidor DayZ

```bash
ssh dayz@<IP_PUBLICO>
sudo su - dayz
./install_dayz.sh  # Atualiza automaticamente
```

### Editar Configuração

```bash
nano /home/dayz/dayzserver/serverDZ.cfg
sudo systemctl restart dayz-server  # Reiniciar após mudanças
```

### Backup de Configuração

```bash
# Backup do serverDZ.cfg
scp dayz@<IP_PUBLICO>:/home/dayz/dayzserver/serverDZ.cfg ./backup/

# Backup do Terraform state
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)
```

---

## 🔧 Troubleshooting

### Erro: Provider version mismatch

**Sintoma**:
```
Error: locked provider registry.terraform.io/oracle/oci 7.0.0 does not match 
configured version constraint ~> 7.30.0
```

**Solução**:
```bash
terraform init -upgrade
```

**Explicação**: O arquivo `.terraform.lock.hcl` tinha uma versão antiga. O `-upgrade` atualiza para a versão especificada no `main.tf`.

### Erro: Authentication failed

**Sintoma**:
```
Error: Service error:NotAuthenticated
```

**Solução**:
```bash
# Verificar perfil
cat ~/.oci/config | grep -A 5 "\[devopsguide\]"

# Testar autenticação
oci iam region list --profile devopsguide

# Verificar:
# 1. Arquivo de chave existe e tem permissões corretas
# 2. Fingerprint está correto
# 3. User OCID e Tenancy OCID estão corretos
```

### Erro: Image not found

**Sintoma**:
```
Error: 404-NotAuthorizedOrNotFound
```

**Solução**:
1. Verificar se a imagem existe na região:
   ```bash
   oci compute image list \
     --compartment-id <COMP_ID> \
     --operating-system "Canonical Ubuntu" \
     --operating-system-version "24.04" \
     --profile devopsguide
   ```

2. Se não encontrar, especificar OCID manualmente em `terraform.tfvars`:
   ```hcl
   ubuntu_image_ocid = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaa..."
   ```

### Erro: Insufficient permissions

**Sintoma**:
```
Error: 403-NotAuthorized
```

**Solução**: Verificar políticas IAM. O usuário precisa de:
- `manage` em `instance-family` no compartment
- `manage` em `virtual-network-family` no compartment

### Erro: Cannot parse request (400-CannotParseRequest)

**Sintoma**:
```
Error: 400-CannotParseRequest, Incorrectly formatted request.
```

**Possíveis Causas e Soluções**:

1. **Formato incorreto do `availability_domain`** (mais comum):
   - ❌ ERRADO: `agak:SA-SAOPAULO-1-AD-1` (formato legado)
   - ✅ CORRETO: `SA-SAOPAULO-1-AD-1` (sem prefixo)

2. **Verificar formato correto do AD**:
   ```bash
   oci iam availability-domain list \
     --compartment-id <COMP_ID> \
     --profile devopsguide
   ```
   Use o campo `name` do resultado.

3. **Problema com user_data muito grande**:
   - Se o user-data.sh for muito grande (>16KB após base64), pode causar erro
   - Solução: Simplificar o script ou dividir em partes

4. **Problema com formato de campos**:
   - Verificar se `assign_public_ip` é boolean `true` (não string `"true"`)
   - Verificar se todos os OCIDs estão corretos

5. **Debug detalhado**:
   ```bash
   # Habilitar debug do Terraform
   export TF_LOG=DEBUG
   terraform apply 2>&1 | tee terraform-debug.log
   
   # Procurar por "CannotParseRequest" no log
   grep -A 20 "CannotParseRequest" terraform-debug.log
   ```

**Solução rápida**: Verifique se o `oci_ad` no `terraform.tfvars` está sem o prefixo `agak:`.

### Erro: Cannot create compartment (404-NotAuthorizedOrNotFound)

**Sintoma**:
```
Error: 404-NotAuthorizedOrNotFound, Authorization failed or requested resource not found
Suggestion: Either the resource has been deleted or service Identity Compartment need policy to access this resource.
```

**Causa**: Usuário não tem permissão para criar compartments.

**Solução**:
✅ **Já resolvido!** O código está configurado para usar um compartment existente por padrão. Certifique-se de que:
1. O `comp_id` no `terraform.tfvars` aponta para um compartment existente (ou tenancy root)
2. Você tem permissões para criar recursos nesse compartment
3. Se você realmente precisa criar um novo compartment, precisa de permissão `manage compartment` no tenancy e descomentar o recurso em `compartments.tf`

### Erro: "No subscription" ou "Missing configuration" ao instalar DayZ Server

**Causa**: App ID incorreto ou ordem incorreta dos parâmetros.

**Solução**:
1. **Verificar App ID correto**: O App ID do DayZ Server é `223350` (não `2233500`!)
   - Verifique nas propriedades do "DayZ Server" no Steam: App ID deve ser `223350`

2. **Ordem correta dos parâmetros**:
   ```bash
   # ✅ CORRETO: +force_install_dir ANTES de +login
   ./steamcmd.sh +force_install_dir /home/dayz/dayzserver +login thefly72003 +app_update 223350 validate +quit
   
   # ❌ ERRADO: +login antes de +force_install_dir
   ./steamcmd.sh +login thefly72003 +force_install_dir /home/dayz/dayzserver +app_update 223350 validate +quit
   ```

3. **Se ainda não funcionar**, tente sem `validate` primeiro:
   ```bash
   ./steamcmd.sh +force_install_dir /home/dayz/dayzserver +login thefly72003 +app_update 223350 +quit
   ```

4. **Limpar cache e tentar novamente**:
   ```bash
   rm -rf ~/Steam/appcache ~/Steam/steamapps/downloading
   ./steamcmd.sh +force_install_dir /home/dayz/dayzserver +login thefly72003 +app_update 223350 validate +quit
   ```

### Erro: "[ERROR][Server config] :: instanceId parameter is mandatory"

**Sintoma**: Servidor falha ao iniciar com erro sobre `instanceId` obrigatório.

**Causa**: O parâmetro `instanceId` é obrigatório no `serverDZ.cfg` desde versões recentes do DayZ Server.

**Solução**:
```bash
sudo su - dayz
cd /home/dayz/dayzserver
echo "instanceId = 1;" >> serverDZ.cfg
```

**Verificar se foi adicionado**:
```bash
grep instanceId serverDZ.cfg
```

**Nota**: O `instanceId` deve ser um inteiro de 32 bits válido (geralmente `1` para servidor único).

### Erro: "[ERROR][Server config] :: Server config not found!"

**Sintoma**: Servidor não encontra o arquivo `serverDZ.cfg` mesmo que ele exista.

**Causa**: O parâmetro `-config=` com caminho relativo pode falhar dependendo do diretório de trabalho.

**Solução**: Use sempre caminho absoluto:

```bash
# ❌ ERRADO (pode falhar)
-config=serverDZ.cfg

# ✅ CORRETO (sempre funciona)
-config=/home/dayz/dayzserver/serverDZ.cfg
```

**Atualizar o systemd service**:
```bash
sudo sed -i 's|-config=serverDZ.cfg|-config=/home/dayz/dayzserver/serverDZ.cfg|' /etc/systemd/system/dayz-server.service
sudo systemctl daemon-reload
sudo systemctl restart dayz-server
```

### Erro: "Server creation failed : 2302"

**Sintoma**: Servidor inicia mas termina imediatamente com erro sobre porta 2302.

**Causas comuns**:

1. **Falta o parâmetro `instanceId` no `serverDZ.cfg`** (veja solução acima)

2. **Caminho do `-config=` incorreto** (veja solução acima)

3. **Falta parâmetro `-mission`**:
   ```bash
   # Adicionar na linha de comando
   -mission=dayzOffline.chernarusplus
   ```

4. **Parâmetros de inicialização incompletos**:
   ```bash
   # Comando completo que funciona:
   ./DayZServer_x64 \
     -config=/home/dayz/dayzserver/serverDZ.cfg \
     -port=2302 \
     -profiles=profile \
     -freezecheck \
     -cpuCount=2 \
     -dologs \
     -adminlog \
     -netlog \
     -scrAllowFileWrite \
     -mission=dayzOffline.chernarusplus \
     -do
   ```

**Verificar se o servidor está realmente rodando**:
```bash
# Verificar porta
sudo ss -tulpn | grep 2302

# Verificar processo
ps aux | grep DayZServer

# Ver logs
tail -50 /home/dayz/dayzserver/profile/error.log
```

### Erro: "Mission script has no main function, player connect will stay disabled!"

**Sintoma**: 
```
Mission script has no main function, player connect will stay disabled!
Mission script has no main function, player connect will stay disabled!
```

**Causa**: O servidor está usando a missão **offline** (`dayzOffline.chernarusplus`) que não permite conexões de jogadores. A missão offline usa `InitOffline()` ao invés de `InitOnline()`.

**Solução**: Criar uma missão online a partir da missão offline:

1. **Conectar ao servidor**:
   ```bash
   ssh -i ~/.ssh/instance-oci.key ubuntu@<IP_PUBLICO>
   ```

2. **Criar missão online** (copiar e modificar):
   ```bash
   sudo su - dayz
   cd /home/dayz/dayzserver/mpmissions
   
   # Copiar missão offline para online
   cp -r dayzOffline.chernarusplus dayz.chernarusplus
   
   # Modificar init.c para modo online
   sed -i 's/InitOffline()/InitOnline()/g' dayz.chernarusplus/init.c
   
   # Verificar se foi modificado corretamente
   head -10 dayz.chernarusplus/init.c
   # Deve mostrar: ce.InitOnline(); (não InitOffline())
   ```

3. **Atualizar systemd service**:
   ```bash
   # Editar o service para usar a missão online
   sudo sed -i 's/-mission=dayzOffline.chernarusplus/-mission=dayz.chernarusplus/g' /etc/systemd/system/dayz-server.service
   
   # Recarregar systemd
   sudo systemctl daemon-reload
   
   # Reiniciar servidor
   sudo systemctl restart dayz-server
   ```

4. **Verificar se o problema foi resolvido**:
   ```bash
   # Aguardar alguns segundos e verificar logs
   sleep 10
   
   # Verificar se a mensagem de erro desapareceu
   sudo journalctl -u dayz-server --since '5 minutes ago' --no-pager | \
     grep -i 'mission script has no main function'
   
   # Se não retornar nada, o problema foi resolvido!
   # Se ainda aparecer, verifique se a missão foi criada corretamente
   ```

5. **Verificar status completo**:
   ```bash
   # Verificar se está conectado ao Steam
   sudo journalctl -u dayz-server --no-pager | grep -i 'connected to steam' | tail -1
   
   # Verificar se BattlEye está ativo
   sudo journalctl -u dayz-server --no-pager | grep -i 'battleye.*initialized' | tail -1
   
   # Verificar se a missão foi lida
   sudo journalctl -u dayz-server --no-pager | grep -i 'mission read' | tail -1
   ```

**Nota**: O `user-data.sh` já foi atualizado para usar `dayz.chernarusplus` por padrão em futuros deploys. Se você fizer um novo deploy, a missão online será criada automaticamente.

**Verificação rápida**:
```bash
# Verificar qual missão está configurada
sudo systemctl cat dayz-server | grep -i mission

# Verificar se a missão online existe
sudo su - dayz -c 'ls -la /home/dayz/dayzserver/mpmissions/ | grep dayz.chernarusplus'

# Verificar init.c da missão online
sudo su - dayz -c 'grep -i "InitOnline\|InitOffline" /home/dayz/dayzserver/mpmissions/dayz.chernarusplus/init.c'
# Deve mostrar: ce.InitOnline(); (não InitOffline())
```

### Servidor não aparece na lista do Steam / Direct Connect não funciona

**Sintoma**: Servidor está rodando, mas não aparece na lista do Steam nem aceita conexões diretas.

**Causas comuns e soluções**:

1. **Servidor ainda está carregando o mundo**:
   - O servidor DayZ leva **5-10 minutos** para carregar completamente o mundo Chernarus
   - Aguarde pelo menos 10 minutos após iniciar o servidor
   - Verifique os logs: `sudo journalctl -u dayz-server -f`
   - Procure por mensagens indicando que o mundo foi carregado

2. **Steam Master Server ainda não registrou o servidor**:
   - Pode levar **10-15 minutos** para o servidor aparecer na lista pública do Steam
   - Isso é normal para servidores novos
   - O servidor precisa estar rodando e conectado ao Steam por algum tempo

3. **Verificar se todas as portas estão abertas**:
   ```bash
   # No servidor
   sudo ufw status | grep -E '2302|27016'
   sudo ss -tulpn | grep -E '2302|27016'
   
   # Deve mostrar:
   # - 2302/udp (porta do jogo)
   # - 27016/udp (porta de query do Steam - ESSENCIAL!)
   ```

4. **Verificar conectividade externa**:
   ```bash
   # Do seu computador (não do servidor)
   # Teste se a porta está acessível
   telnet 137.131.231.155 2302
   # ou
   nc -u -v 137.131.231.155 2302
   ```

5. **Verificar se BattlEye está ativo**:
   - BattlEye é **obrigatório** para servidores aparecerem na lista pública
   - Verifique nos logs: `sudo journalctl -u dayz-server | grep BattlEye`
   - Deve mostrar: `BattlEye Server: Initialized`
   - **NÃO use `-noBattlEye`** no comando de inicialização

6. **Verificar configuração do servidor**:
   ```bash
   sudo cat /home/dayz/dayzserver/serverDZ.cfg
   ```
   - `hostname` deve estar definido
   - `password = "";` para servidor público (sem senha)
   - `instanceId = 1;` deve estar presente

7. **Tentar Direct Connect com formato correto**:
   - No DayZ Launcher: `DIRECT CONNECT`
   - Digite: `137.131.231.155:2302` (sem espaços, apenas IP:PORTA)
   - Pressione Enter
   - Aguarde alguns segundos - pode demorar para conectar

8. **Verificar firewall local (seu computador)**:
   - Windows: Verifique se o firewall não está bloqueando DayZ
   - Linux: Verifique `iptables` ou `ufw` local
   - Antivírus pode bloquear conexões UDP

9. **Reiniciar o servidor** (último recurso):
   ```bash
   sudo systemctl restart dayz-server
   # Aguarde 10-15 minutos após reiniciar
   ```

**Checklist de diagnóstico**:
```bash
# 1. Servidor está rodando?
sudo systemctl is-active dayz-server
# Deve retornar: active

# 2. Portas estão abertas?
sudo ss -tulpn | grep -E '2302|27016'
# Deve mostrar ambas as portas UDP

# 3. Conectado ao Steam?
sudo journalctl -u dayz-server | grep "Connected to Steam"
# Deve mostrar a mensagem

# 4. BattlEye ativo?
sudo journalctl -u dayz-server | grep "BattlEye Server: Initialized"
# Deve mostrar a mensagem

# 5. Uptime do servidor?
sudo systemctl show dayz-server -p ActiveEnterTimestamp --value
# Se iniciou há menos de 10 minutos, aguarde mais tempo
```

**Se nada funcionar**:
1. Verifique se o IP público está correto: `curl ifconfig.me` (no servidor)
2. Verifique se há algum firewall intermediário (ISP, roteador, etc.)
3. Tente conectar de outro computador/rede
4. Verifique os logs completos: `sudo journalctl -u dayz-server -n 200`

### Servidor carregando com muitos warnings (PerfWarning, Warning: No components)

**Sintoma**: Os logs estão cheios de warnings como:
```
PerfWarning: Way too much components (688) in dz\structures\wrecks\ships\proxy\beams_front_a.p3d:geometryFire
Warning: No components in dz\structures\wrecks\ships\proxy\covers_back_a.p3d:geometry
```

**Causa**: Isso é **NORMAL** durante o carregamento do mundo Chernarus. O servidor está processando milhares de objetos 3D, texturas e estruturas do mapa.

**Solução**: **Não é um problema!** Apenas aguarde. O carregamento leva **5-10 minutos**.

**Como monitorar o progresso sem os warnings**:
```bash
# Filtrar warnings e ver apenas mensagens importantes
sudo journalctl -u dayz-server -f | grep -v PerfWarning | grep -v "Warning: No components" | grep -v "Warning: Shape"

# Ou verificar mensagens importantes nos logs
sudo journalctl -u dayz-server --no-pager | grep -iE 'connected|steam|battleye|mission read|world|ready|spawn' | tail -20
```

**Verificar se o servidor está processando ativamente**:
```bash
# Verificar uso de CPU (deve estar alto durante carregamento)
ps aux | grep DayZServer | grep -v grep | awk '{print "CPU: " $3 "% | MEM: " $4 "%"}'
# Durante carregamento: CPU deve estar entre 80-120%
# Após carregamento: CPU deve estar entre 10-30%

# Verificar tempo desde início
START=$(sudo systemctl show dayz-server -p ActiveEnterTimestamp --value)
NOW=$(date +%s)
START_EPOCH=$(date -d "$START" +%s 2>/dev/null || echo $NOW)
MINUTES=$(( (NOW - START_EPOCH) / 60 ))
echo "Servidor rodando há: $MINUTES minutos"
```

**Sinais de que o carregamento terminou**:
- CPU diminui para 10-30%
- Warnings param de aparecer constantemente
- Mensagens como "World loaded" ou "Ready to accept connections" aparecem
- Portas 2302 e 27016 estão abertas e escutando

**Comando completo de verificação de progresso**:
```bash
echo '=== VERIFICAÇÃO DE PROGRESSO ===' && \
echo '' && \
echo '1. Tempo desde início:' && \
START=$(sudo systemctl show dayz-server -p ActiveEnterTimestamp --value) && \
NOW=$(date +%s) && \
START_EPOCH=$(date -d "$START" +%s 2>/dev/null || echo $NOW) && \
MINUTES=$(( (NOW - START_EPOCH) / 60 )) && \
echo "   Rodando há: $MINUTES minutos" && \
echo '' && \
echo '2. CPU e Memória:' && \
ps aux | grep DayZServer | grep -v grep | awk '{print "   CPU: " $3 "% | MEM: " $4 "%"}' && \
echo '' && \
echo '3. Portas abertas:' && \
sudo ss -tulpn | grep -E '2302|27016' | grep udp && \
echo '' && \
echo '4. Conectado ao Steam:' && \
sudo journalctl -u dayz-server --no-pager | grep -i 'connected to steam' | tail -1 && \
echo '' && \
echo '5. BattlEye:' && \
sudo journalctl -u dayz-server --no-pager | grep -i 'battleye.*initialized' | tail -1
```

### Servidor DayZ não inicia

**Solução**:
1. Verificar os logs:
   ```bash
   sudo journalctl -u dayz-server -n 50
   ```

2. Verificar se o servidor foi instalado:
   ```bash
   ls -la /home/dayz/dayzserver/DayZServer_x64
   ```

3. Se não estiver instalado, execute:
   ```bash
   sudo su - dayz
   cd /opt/steamcmd
   ./steamcmd.sh +force_install_dir /home/dayz/dayzserver +login thefly72003 +app_update 223350 validate +quit
   chmod +x /home/dayz/dayzserver/DayZServer_x64
   ```

### Portas não acessíveis

**Solução**:
1. Verificar o Security List no Console OCI
2. Verificar o firewall no servidor:
   ```bash
   sudo ufw status
   ```

3. Testar a conectividade:
   ```bash
   # Do seu computador
   telnet <IP_PUBLICO> 2302
   ```

### Problemas de Performance

O servidor está configurado com:
- 2 OCPUs
- 16GB RAM
- Otimizações de rede (BBR, buffer sizes)

Se ainda houver problemas:
1. Verificar o uso de recursos:
   ```bash
   htop
   ```

2. Ajustar `maxPlayers` no `serverDZ.cfg` se necessário

### User-data não executa

**Solução**:
1. Verificar se user-data foi aplicado:
   ```bash
   # Na instância
   sudo cat /var/lib/cloud/instance/user-data.txt
   ```

2. Verificar logs do cloud-init:
   ```bash
   sudo cat /var/log/cloud-init-output.log
   sudo cat /var/log/cloud-init.log
   ```

### Comandos de Diagnóstico

```bash
# Verificar estado do Terraform
terraform show
terraform plan

# Verificar recursos OCI
oci compute instance list \
  --compartment-id <COMP_ID> \
  --profile devopsguide

# Ver console logs da instância
oci compute instance get-console-content \
  --instance-id <INSTANCE_ID> \
  --profile devopsguide
```

### Logs Importantes

**No Servidor**:
- User-data: `/var/log/user-data.log`
- Cloud-init: `/var/log/cloud-init.log`, `/var/log/cloud-init-output.log`
- Systemd (DayZ): `journalctl -u dayz-server -f`
- DayZ Server: `/home/dayz/dayzserver/logs/*.log`
- Sistema: `/var/log/syslog`

**No Terraform**:
```bash
# Habilitar debug
export TF_LOG=DEBUG
terraform apply
```

---

## 🔒 Segurança

### Camadas de Segurança

1. **OCI Security Lists**: Firewall no nível de rede
2. **UFW**: Firewall no nível de sistema
3. **Fail2ban**: Proteção contra ataques de força bruta SSH
4. **Usuário dedicado**: Servidor roda como usuário `dayz` (não root)
5. **SSH Key**: Autenticação por chave (sem senha)

### Boas Práticas

- ✅ Altere `passwordAdmin` no `serverDZ.cfg` após instalação
- ✅ Use senhas fortes
- ✅ Mantenha sistema atualizado
- ✅ Monitore logs regularmente
- ✅ Faça backups da configuração
- ✅ Rotacione chaves SSH regularmente
- ✅ Limite acesso SSH por IP se possível (via Security List)

### Configurações de Segurança Aplicadas

- **Firewall (UFW)**: Configurado com regras mínimas necessárias
- **Fail2ban**: Proteção SSH com ban time de 3600 segundos
- **Usuário não-root**: Servidor executa como `dayz` com sudo sem senha
- **Security Lists**: Regras de firewall no nível da OCI
- **SSH Key-only**: Autenticação apenas por chave SSH

---

## 💰 Custos

### Recursos Principais

Com VM.Standard.E4.Flex (2 OCPUs, 16GB RAM) na região sa-saopaulo-1:
- **Compute**: ~$0.XX/hora (consulte a calculadora OCI)
- **Networking**: Geralmente incluído no Always Free
- **Storage**: Boot volume incluído (~50GB)

**Nota**: Verifique os preços atuais na [calculadora de preços da OCI](https://www.oracle.com/cloud/cost-estimator.html).

### Otimizações de Custo

- Use Always Free tier quando possível
- Snapshots são mais baratos que volumes extras
- Monitore uso e ajuste shape se necessário
- Desligue instância quando não estiver em uso

---

## ❓ FAQ

### P: Por que preciso do `-upgrade` no terraform init?

**R**: O arquivo `.terraform.lock.hcl` tinha uma versão antiga do provider. O `-upgrade` atualiza para a versão especificada no `main.tf` (7.30.0).

### P: Posso usar outra região?

**R**: Sim! Apenas altere `oci_region` e `oci_ad` no `terraform.tfvars`. Verifique se a imagem Ubuntu está disponível na região.

### P: Posso mudar o shape?

**R**: Sim! Edite `instances.tf` e ajuste `shape` e `shape_config`. Verifique compatibilidade da imagem com o novo shape.

### P: Como atualizo o servidor DayZ?

**R**: Execute `./install_dayz.sh` novamente. O SteamCMD atualiza automaticamente.

### P: Onde estão os logs?

**R**: 
- User-data: `/var/log/user-data.log`
- DayZ: `/home/dayz/dayzserver/logs/`
- Systemd: `journalctl -u dayz-server`

### P: Como adiciono mods?

**R**: Veja a seção completa [Configurar Mods](#63-configurar-mods-se-seu-servidor-usa-mods) no README. Resumo rápido:

1. Obtenha os Workshop IDs dos mods (da URL do Steam Workshop)
2. Baixe os mods via SteamCMD:
   ```bash
   ./steamcmd.sh +login seu_usuario +workshop_download_item 221100 WORKSHOP_ID +quit
   ```
3. Configure no `serverDZ.cfg`:
   ```cpp
   mods[] = {"1234567890", "2345678901"};
   ```
4. Reinicie o servidor

**Nota**: `221100` é o App ID do DayZ (não do servidor). Os mods são baixados em `~/Steam/steamapps/workshop/content/221100/`.

### P: Por que o servidor termina imediatamente após iniciar?

**R**: Verifique os seguintes pontos:

1. **`instanceId` no `serverDZ.cfg`**: Deve estar presente:
   ```bash
   grep instanceId /home/dayz/dayzserver/serverDZ.cfg
   # Deve mostrar: instanceId = 1;
   ```

2. **Caminho absoluto no `-config=`**: O systemd service usa caminho absoluto. Se iniciar manualmente, use:
   ```bash
   -config=/home/dayz/dayzserver/serverDZ.cfg
   ```

3. **Parâmetros obrigatórios**: Certifique-se de incluir:
   - `-mission=dayzOffline.chernarusplus` (ou outro mapa)
   - `-do` (modo dedicado)
   - `-config=/home/dayz/dayzserver/serverDZ.cfg` (caminho absoluto)
   - **NÃO use `-noBattlEye`** - BattlEye é necessário para servidores públicos aparecerem na lista do Steam

4. **Verificar logs**:
   ```bash
   tail -100 /home/dayz/dayzserver/profile/error.log
   sudo journalctl -u dayz-server -n 50
   ```

Veja também a seção [Troubleshooting](#-troubleshooting) para mais detalhes.

### P: Posso usar um compartment existente?

**R**: Sim! O código já está configurado para usar um compartment existente por padrão. Basta definir `comp_id` no `terraform.tfvars` com o OCID do compartment desejado. Se você tiver permissões para criar compartments, pode descomentar o recurso em `compartments.tf`.

### P: Como faço backup?

**R**: 
- Configuração: Copie `serverDZ.cfg`
- Terraform state: Copie `terraform.tfstate`
- Boot volume: Crie snapshot via Console OCI

### P: Como destruir tudo?

**R**: Execute `cd terraform && terraform destroy`. **Atenção**: Isso deleta permanentemente todos os recursos!

---

## 🗑️ Destruir a Infraestrutura

Para remover todos os recursos criados:

```bash
cd terraform
terraform destroy
```

**⚠️ IMPORTANTE**: O Terraform reconhece todos os recursos mesmo após a reorganização porque:
- O arquivo `terraform.tfstate` foi movido junto para `terraform/`
- Os caminhos relativos foram atualizados (`../scripts/user-data.sh`)
- O estado contém todas as referências aos recursos OCI criados

O `terraform destroy` funcionará normalmente e removerá todos os recursos gerenciados.

**⚠️ Atenção**: Isso irá deletar permanentemente:
- A instância Compute
- Todos os dados do servidor DayZ
- A VCN e todos os recursos de rede
- O compartment (se não houver outros recursos)

---

## 📚 Referências

### Documentação

- [Documentação OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [DayZ Server Documentation](https://dayz.com/)
- [SteamCMD Documentation](https://developer.valvesoftware.com/wiki/SteamCMD)

### Links Úteis

- [OCI Console](https://cloud.oracle.com/)
- [OCI CLI Documentation](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/)
- [Terraform OCI Examples](https://github.com/oracle-terraform-modules)

---

## 📝 Variáveis Principais

| Variável | Descrição | Obrigatória | Exemplo |
|----------|-----------|-------------|---------|
| `oci_region` | Região OCI | Sim | `sa-saopaulo-1` |
| `oci_ad` | Availability Domain | Sim | `SA-SAOPAULO-1-AD-1` (sem prefixo agak:) |
| `comp_id` | OCID do compartment/tenancy | Sim | `ocid1.tenancy.oc1..aaaaaaa...` |
| `ssh_instances_key` | Chave SSH pública | Sim | `ssh-rsa AAAAB3NzaC1...` |
| `ubuntu_image_ocid` | OCID da imagem Ubuntu (opcional) | Não | `ocid1.image.oc1...` |

---

## 🤝 Contribuindo

Para melhorias ou correções, abra uma issue ou pull request.

---

## 📄 Licença

Este projeto é fornecido "como está" para fins educacionais e de uso pessoal.

---

**Última atualização**: 2025-01-XX  
**Versão do Provider OCI**: ~> 7.30.0  
**Versão do Terraform**: >= 1.0  
**Versão do Ubuntu**: 2025.07.23-0

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Consulte a seção [Troubleshooting](#-troubleshooting)
2. Verifique os [logs importantes](#logs-importantes)
3. Consulte a [documentação oficial](#-referências)

---

*Documentação completa e centralizada - Servidor DayZ OCI*
