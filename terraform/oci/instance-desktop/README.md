# Instance desktop na OCI (Terraform)

Material de referência e **estudo** do stack `instance-desktop`: uma VCN com **OpenVPN** (subnet pública, IP público) e um **Ubuntu com área de trabalho remota** (subnet privada, sem IP público), saída à internet via **NAT Gateway** e acesso a serviços Oracle via **Service Gateway**.

### Resumo rápido (visão de estudo)

| Pergunta | Resposta em uma linha |
|----------|------------------------|
| O que este Terraform entrega? | Duas VMs: **VPN** (com IP público) e **desktop** (só IP privado), mais rede OCI completa. |
| Como entro no desktop pela internet? | **Não entra direto**: conecta na **VPN** com o `.ovpn`, depois **SSH/RDP** no IP **privado** do desktop. |
| Onde está cada coisa no código? | VPN → `compute_vpn.tf` + `scripts/openvpn-ubuntu-install.sh`; desktop → `compute_desktop.tf` + `scripts/cloud-init-desktop.sh`. |
| Por que o primeiro boot do desktop é “delicado”? | **Lock do `apt`**; o script para **unattended-upgrades** e **espera** a fila antes do `apt-get` (sem MIME multipart — na OCI a parte shell do multipart pode **não rodar**). |

**Vocabulário:** mantemos termos usuais em inglês no dia a dia DevOps (`apply`, `output`, `user_data`). O restante do texto está em **português brasileiro**.

---

## Como usar este material

| Se você quer… | Comece por… |
|---------------|-------------|
| Entender *por que* existem duas subnets e dois gateways | [Conceitos essenciais](#1-conceitos-essenciais) e [Arquitetura de rede](#3-arquitetura-de-rede) |
| Subir o ambiente do zero | [Pré-requisitos](#5-pré-requisitos) → [Configuração](#6-configuração-terraformtfvars) → [Comandos Terraform](#7-comandos-terraform) → [Tempo de espera e checklist pós-apply](#71-tempo-de-espera-e-checklist-pós-apply) |
| Conectar na VPN e no desktop depois do `apply` | [Fluxo pós-deploy: VPN → desktop](#8-fluxo-pós-deploy-vpn--desktop) |
| Entender só OpenVPN (scripts, `.ovpn`, `/opt`) | [OpenVPN em profundidade](#9-openvpn-em-profundidade) |
| Entender só o desktop (XFCE, xrdp, cloud-init) | [Desktop: cloud-init e RDP](#10-desktop-cloud-init-e-rdp) |
| Depurar problemas | [Resolução de problemas](#11-resolução-de-problemas) |

**Sugestão de leitura na primeira vez:** seções 1 → 3 → 5 → 6 → 7 (**incluindo §7.1** sobre espera pós-apply) → 8 (cerca de 25–35 minutos de leitura). As demais servem de apoio quando for implementar ou revisar.

---

## Índice

1. [Conceitos essenciais](#1-conceitos-essenciais)
2. [O que o Terraform cria](#2-o-que-o-terraform-cria)
3. [Arquitetura de rede](#3-arquitetura-de-rede)
4. [Arquivos do módulo (mapa do repositório)](#4-arquivos-do-módulo-mapa-do-repositório)
5. [Pré-requisitos](#5-pré-requisitos)
6. [Configuração (`terraform.tfvars`)](#6-configuração-terraformtfvars)
7. [Comandos Terraform](#7-comandos-terraform) — inclui [checklist após o `apply`](#71-tempo-de-espera-e-checklist-pós-apply)
8. [Fluxo pós-deploy: VPN → desktop](#8-fluxo-pós-deploy-vpn--desktop)
9. [OpenVPN em profundidade](#9-openvpn-em-profundidade)
10. [Desktop: cloud-init e RDP](#10-desktop-cloud-init-e-rdp)
11. [Resolução de problemas](#11-resolução-de-problemas)
12. [Consistência e limitações](#12-consistência-e-limitações)
13. [Segurança](#13-segurança)
14. [Autoavaliação (checklist de estudo)](#14-autoavaliação-checklist-de-estudo)
15. [Referências](#15-referências)

---

## 1. Conceitos essenciais

### 1.1 Objetivos de aprendizagem

Ao final deste documento você deve ser capaz de:

- Explicar **por que** o desktop não tem IP público e ainda assim acessa internet e VPN.
- Descrever o papel do **NAT Gateway**, **Service Gateway**, **Internet Gateway** e **NSG/Security List**.
- Orquestrar o fluxo: **cliente OpenVPN → IP privado do desktop (SSH/RDP)**.
- Localizar no repositório onde estão **VPN** (`compute_vpn.tf` + script) e **desktop** (`compute_desktop.tf` + cloud-init).
- Saber onde olhar quando **VPN não conecta** ou **RDP não responde**.
- Estimar **quanto esperar** após o `terraform apply` antes de validar as VMs e interpretar **`cloud-init status`**.

### 1.2 Glossário rápido

| Termo | Em uma frase |
|-------|----------------|
| **VCN** | Rede virtual na OCI; aqui concentra subnets, rotas e gateways. |
| **Subnet pública (VPN)** | Pode receber IP público na VNIC; rota default costuma ir para o **Internet Gateway**. |
| **Subnet privada (desktop)** | `prohibit_public_ip_on_vnic = true`; sem IP público; saída via **NAT Gateway**. |
| **Internet Gateway (IGW)** | Entrada/saída entre a VCN e a internet (ex.: OpenVPN acessível de fora). |
| **NAT Gateway** | Permite que recursos **sem** IP público iniciem conexões de saída para a internet. |
| **Service Gateway (SGW)** | Acesso à **Oracle Services Network** (repos, APIs Oracle, etc.) sem sair pela internet pública. |
| **NSG / Security List** | Firewall na nuvem: quem pode falar com qual IP/porta (por exemplo SSH/RDP só de certos CIDRs). |
| **`user_data`** | Script ou dados injetados no **primeiro boot** da instância (cloud-init); não reaplica sozinho em VM antiga. |
| **cloud-init** | Serviço que aplica o `user_data` no boot; use `cloud-init status` para saber se o primeiro boot **terminou** (`done` vs `running`). |
| **Split tunnel (OpenVPN)** | Só o tráfego para `vcn_cidr` (e rotas publicadas) passa pelo túnel; o resto sai pela rede local do cliente. |
| **Pool OpenVPN** | Faixa de IPs dos clientes conectados (no script padrão **10.8.0.0/24**); deve bater com `openvpn_client_cidr` no Terraform. |

### 1.3 Objetivo do projeto (negócio / operação)

- **Desktop** acessível por **SSH (22)** e **RDP (3389)** apenas a partir da **subnet da VPN** ou do **pool de clientes OpenVPN** (regras em NSG + Security List).
- **Saída** do desktop: internet via **NAT**; serviços Oracle via **Service Gateway**.
- **Servidor OpenVPN** exposto na internet nas portas que você configurar (**UDP** em `openvpn_port`, **SSH** para administração, conforme CIDRs de ingresso).

---

## 2. O que o Terraform cria

| Camada | Recursos principais | Para que estudar |
|--------|---------------------|------------------|
| **Identity** | `oci_identity_compartment` (home region) + `time_sleep` (propagação) | Compartment filho isolando custo e políticas. |
| **Rede** | VCN, IGW, NAT, SGW, 2 route tables, 2 subnets, Security Lists, NSG | É o “esqueleto” de tráfego; sem isso as VMs não conversam certo com a internet/OSN. |
| **Compute** | Duas `oci_core_instance`: **OpenVPN** e **desktop** | Duas funções distintas: entrada VPN vs. workstation interna. |
| **Dados** | `oci_core_services` (OSN para SGW), data sources de VNIC para outputs | OSN é necessário para anexar o Service Gateway corretamente. |

---

## 3. Arquitetura de rede

### 3.1 Diagrama lógico

```text
                    Internet
                        │
                        ▼
              ┌─────────────────┐
              │ Internet Gateway │  ◄── subnet VPN (IP público na VM OpenVPN)
              └────────┬────────┘
                       │
    ┌──────────────────┴──────────────────┐
    │                 VCN (ex.: /16)        │
    │  ┌─────────────────────────────┐    │
    │  │ Subnet VPN (pública / IGW)  │    │
    │  │   • Instância OpenVPN       │    │
    │  └─────────────────────────────┘    │
    │  ┌─────────────────────────────┐    │
    │  │ Subnet privada (NAT + SGW)  │    │
    │  │   • Desktop (sem IP público)│    │
    │  └─────────────────────────────┘    │
    └─────────────────────────────────────┘
```

### 3.2 Fluxo mental (estudo)

```mermaid
flowchart TB
  subgraph internet [Internet]
    Cliente[Cliente com arquivo .ovpn]
  end
  subgraph vcn [VCN]
    VPN[VM OpenVPN - subnet pública]
    Desk[VM Desktop - subnet privada]
  end
  Cliente -->|UDP openvpn_port| VPN
  Cliente -->|SSH/RDP após rota para vcn_cidr| Desk
  Desk -->|Saída 0.0.0.0/0| NAT[NAT Gateway]
  Desk -->|Serviços Oracle| SGW[Service Gateway]
```

- **Subnet privada:** `prohibit_public_ip_on_vnic = true`; rotas típicas: `0.0.0.0/0` → **NAT**; prefixo da **OSN** → **Service Gateway**.
- **Subnet VPN:** IP público permitido na VNIC; rota default → **Internet Gateway**.

**Por que duas subnets?** Separar **superfície exposta** (VPN) de **carga interna** (desktop sem IP público), alinhando ao princípio de menor exposição direta à internet para o desktop.

---

## 4. Arquivos do módulo (mapa do repositório)

| Arquivo | Função didática |
|---------|-------------------|
| `versions.tf` | Versão mínima do Terraform e *providers*. |
| `providers.tf` | Provider `oci` (workload) e `oci.home` (Identity na home region). |
| `data.tf` | Oracle Services Network (para o Service Gateway). |
| `locals.tf` | Compartment, AD, imagens, OSN. |
| `compartments.tf` | Compartment filho + espera após criação. |
| `network.tf` | VCN, gateways, rotas, subnets, SL, NSG. |
| `compute_vpn.tf` | Instância VPN; `user_data` = `templatefile(openvpn-ubuntu-install.sh)` (modelo wln/psql). |
| `compute_desktop.tf` | Instância desktop; `user_data` = `base64encode(cloud-init-desktop.sh)` (script único). |
| `variables.tf` | Contrato de entrada do módulo. |
| `outputs.tf` | IPs, comandos sugeridos, hints de SSH/RDP/VPN. |
| `scripts/cloud-init-desktop.sh` | Único script de preparação do desktop: primeiro boot via `user_data` (XFCE, xrdp, UFW, `devuser`). |
| `scripts/openvpn-ubuntu-install.sh` | Instala OpenVPN e grava `/opt/openvpn-ubuntu-install.sh` (menu). |
| `terraform.tfvars.example` | Modelo para copiar em `terraform.tfvars`. |

---

## 5. Pré-requisitos

**Dica de estudo:** ajuda ter noções de **Terraform** (`init`, `plan`, `apply`, `output`) e de **rede** (CIDR, rota default, diferença entre IP público e privado). Não é obrigatório dominar OCI antes de ler este README — a tabela **Glossário rápido** (§1.2) cobre os termos usados aqui.

- Terraform **>= 1.3.0** (ver `versions.tf`).
- CLI OCI configurada: `~/.oci/config` com o profile em `oci_config_profile`.
- **Home region** correta em `oci_home_region` (Identity/compartment).
- **Availability Domain** válido em `availability_domain_name` (formato típico: `PREFIXO:REGION-AD-N`).
- Chave **SSH pública** no caminho `ssh_public_key_path`.

---

## 6. Configuração (`terraform.tfvars`)

1. Copie o exemplo: `cp terraform.tfvars.example terraform.tfvars`
2. Preencha no mínimo:
   - `oci_home_region`, `parent_compartment_id`
   - `availability_domain_name`
   - `instance_image_id` (e opcionalmente `vpn_image_id` se for diferente; vazio = mesma imagem do desktop)
   - `ssh_public_key_path` (e `ssh_private_key_path` para outputs de SSH)
3. Ajuste CIDRs para **não se sobreporem** na VCN:
   - `vcn_cidr` (ex.: /16)
   - `private_subnet_cidr` e `vpn_subnet_cidr` (ex.: /24 dentro da VCN)

Variáveis úteis da VPN: `openvpn_port`, `vpn_ssh_ingress_cidr`, `openvpn_udp_ingress_cidr`, `vpn_subnet_cidr`, `openvpn_client_cidr`, `vpn_instance_*`, `extra_admin_cidrs` (detalhes em `variables.tf`).

**Estudo:** o arquivo `terraform.tfvars` costuma estar no `.gitignore` — **não commite** segredos nem OCIDs sensíveis.

---

## 7. Comandos Terraform

```bash
cd /caminho/para/instance-desktop
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Inspeção após o apply:

```bash
terraform output
terraform output -raw vpn_public_ip
```

### 7.1 Tempo de espera e checklist pós-apply

Depois que o **`terraform apply`** termina, as VMs **continuam** trabalhando no primeiro boot: **cloud-init** roda os scripts (`user_data`), instala pacotes e sobe serviços. **Não é instantâneo.**

#### Quanto esperar (ordem de grandeza)

| VM | Tempo típico | O que demora |
|----|----------------|--------------|
| **OpenVPN** | **~5 a 15 minutos** | `apt`, Easy-RSA, OpenVPN, primeiro `.ovpn` |
| **Desktop** | **~15 a 45 minutos** (às vezes até **~60 min** em shape pequeno ou mirror lento) | `apt upgrade`, XFCE, xrdp, muitos pacotes |

**Regra prática:** espere **pelo menos 10 a 15 minutos** após o apply e só então tente **SSH no IP público da VPN**. Para o **desktop**, conte com **20 a 30 minutos** antes de assumir falha — ou acompanhe o log até ele parar de crescer.

**Sinal mais confiável:** na VM, `sudo cloud-init status` deve mostrar **`status: done`**. Enquanto estiver **`running`**, o primeiro boot ainda não terminou.

#### O que checar (ordem sugerida para estudo / operação)

**1) Na sua estação (Terraform)**

```bash
terraform output
```

Anote `vpn_public_ip`, `desktop_private_ip` e os comandos sugeridos pelos outputs.

**2) VM da VPN (IP público — acessível pela internet)**

```bash
ssh -i ~/.ssh/SUA_CHAVE ubuntu@IP_PUBLICO_VPN
sudo cloud-init status
sudo tail -50 /var/log/cloud-init-output.log
```

Validação rápida do OpenVPN:

```bash
sudo test -f /etc/openvpn/client-configs/files/openvpn-config.ovpn && echo "perfil inicial OK"
```

**3) VM do desktop (só IP privado — use SSH a partir da VPN já ligada, ou de outra VM na VCN)**

```bash
ssh -i ~/.ssh/SUA_CHAVE ubuntu@IP_PRIVADO_DESKTOP
sudo cloud-init status
sudo tail -80 /var/log/cloud-init-output.log
```

Validação do RDP / XFCE:

```bash
systemctl is-active xrdp xrdp-sesman
sudo ss -tlnp | grep 3389
test -f /opt/.instance-desktop-rdp-ready && echo "marcador desktop OK"
```

**4) No seu notebook (com VPN OpenVPN conectada)** — teste **RDP** para `IP_PRIVADO_DESKTOP:3389`, usuário **`devuser`**, senha conforme `cloud-init-desktop.sh`.

#### Se ainda estiver “em execução”

Se `cloud-init status` ainda for **`running`** ou o arquivo de log **continuar mudando**, **aguarde mais 10 a 15 minutos** e verifique de novo. Só parta para **§11 (resolução de problemas)** se passar de **~60 minutos** no desktop com erro persistente ou `status: error`.

**Estudo:** o gargalo costuma ser **download/instalação de pacotes**, não o Terraform em si — por isso o tempo varia com rede e tamanho da imagem.

---

## 8. Fluxo pós-deploy: VPN → desktop

### 8.1 Saídas importantes (`terraform output`)

| Output | Uso |
|--------|-----|
| `vpn_public_ip` | IP público do servidor OpenVPN (UDP em `openvpn_port`). |
| `vpn_ssh_cmd` | SSH para administrar a VM da VPN. |
| `openvpn_menu_cmd` | No servidor VPN: `sudo bash /opt/openvpn-ubuntu-install.sh` (menu). |
| `desktop_private_ip` | IP **privado** do desktop. |
| `ssh_cmd` | SSH ao desktop **depois** da VPN (usuário `cloud_init_user`, ex.: `ubuntu`). |
| `rdp_hint` | `IP_PRIVADO:3389` para o cliente RDP **depois** da VPN. |
| `vpn_access_note` | Lembrete sobre CIDRs e regras. |

### 8.2 Passo a passo (ordem didática)

1. **Obtenha o primeiro `.ovpn`** no servidor VPN (perfil padrão `openvpn-config`) — ver [9.3](#93-primeiro-perfil-ovpn).
2. No seu notebook, importe o `.ovpn` no cliente OpenVPN e **conecte** usando o **IP público** da VPN.
3. Com o túnel ativo, o cliente recebe IP do pool (ex.: 10.8.x.x) e passa a alcançar o **`vcn_cidr`** (split tunnel).
4. **SSH** ou **RDP** ao **IP privado** do desktop (`desktop_private_ip` / `rdp_hint`). Não existe rota direta da internet pública para o desktop.

**Usuários:** SSH na imagem costuma ser **`ubuntu`**; sessão **RDP (xrdp)** usa **`devuser`** com a senha definida em `cloud-init-desktop.sh` (**altere a senha** em ambientes reais).

---

## 9. OpenVPN em profundidade

### 9.1 Como o Terraform entrega a VPN

- Em `compute_vpn.tf`, o `user_data` é só `templatefile("scripts/openvpn-ubuntu-install.sh", { vcn_cidr, openvpn_port })`, no mesmo estilo do stack **wln/psql**.
- Ao **final** da instalação inicial, o script grava **`/opt/openvpn-ubuntu-install.sh`**: menu (novo cliente, revogar, remover). A porta no `remote` dos `.ovpn` gerados pelo menu é alinhada com `openvpn_port` (via `sed`), como no wln/psql.
- Se o OpenVPN **já estiver rodando** e o script for executado de novo, o fluxo mostra o **menu** em vez de reinstalar tudo.
- Imagens suportadas no script: **Ubuntu** 20.04 / 22.04 / 24.04.

### 9.2 Arquivos no servidor Linux (mapa mental)

| Caminho | Conteúdo |
|---------|----------|
| `/etc/openvpn/easy-rsa/` | PKI Easy-RSA (CA, servidor, clientes). |
| `/etc/openvpn/server/server.conf` | Configuração do daemon. |
| `/etc/openvpn/client-configs/base.conf` | Base do primeiro cliente (`remote` = IP público no install). |
| `/etc/openvpn/client-configs/files/` | Arquivos `.ovpn` (ex.: `openvpn-config.ovpn`). |
| **`/opt/openvpn-ubuntu-install.sh`** | Menu interativo — comando: `sudo bash /opt/openvpn-ubuntu-install.sh`. |

### 9.3 Primeiro perfil `.ovpn`

- Nome fixo no instalador: **`openvpn-config`**.
- Caminho no servidor: **`/etc/openvpn/client-configs/files/openvpn-config.ovpn`**.
- O arquivo é legível como root; no seu PC use `sudo cat` via SSH.

**Com IP vindo do Terraform** (rode `terraform output` no diretório do stack):

```bash
mkdir -p /home/cleverson/ovpn-clients
VPN_IP="$(terraform output -raw vpn_public_ip)"
ssh -i ~/.ssh/sua_chave.pem ubuntu@"$VPN_IP" \
  'sudo cat /etc/openvpn/client-configs/files/openvpn-config.ovpn' \
  > /home/cleverson/ovpn-clients/openvpn-config.ovpn
```

**Exemplo com variável e chave `instance-oci.key`:**

```bash
mkdir -p /home/cleverson/ovpn-clients
VPN_IP="COLOQUE_AQUI_O_IP_PUBLICO"   # ex.: saída de terraform output -raw vpn_public_ip
ssh -i ~/.ssh/instance-oci.key ubuntu@"$VPN_IP" \
  'sudo cat /etc/openvpn/client-configs/files/openvpn-config.ovpn' \
  > /home/cleverson/ovpn-clients/openvpn-config.ovpn
```

Ajuste o usuário (`ubuntu`) e a chave (`-i`) conforme o seu ambiente.

### 9.4 Perfis adicionais e menu em `/opt`

No servidor VPN:

```bash
sudo bash /opt/openvpn-ubuntu-install.sh
```

- Opção **1**: novo cliente → `.ovpn` em `/etc/openvpn/client-configs/files/<nome>.ovpn`.
- Opções **2** e **3**: revogar ou remover OpenVPN (esta última apaga também `/opt/openvpn-ubuntu-install.sh`).

Não use o modelo antigo `openvpn-add-client` em `/usr/local/bin` — foi substituído por este menu.

### 9.5 Pool 10.8.0.0/24 e `openvpn_client_cidr`

- O instalador usa `server 10.8.0.0 255.255.255.0` (pool de clientes).
- As regras do **desktop** usam `openvpn_client_cidr` (padrão **10.8.0.0/24**) para permitir SSH/RDP a partir desse pool.
- Se mudar o pool no script OpenVPN, atualize **`openvpn_client_cidr`** e o firewall (iptables no script) de forma **coerente**.

### 9.6 Outros repositórios (wln/psql, oke-crs)

- Referência de script: `IaC/terraform/oci/dbsystems/wln/psql/scripts/openvpn-ubuntu-install.sh`.
- Outros projetos (ex.: `oke-crs`) podem ter `user_data` diferente; alinhe scripts se quiser o mesmo menu em `/opt`.

### 9.7 `user_data` e VMs antigas

O cloud-init do `user_data` roda em geral **só no primeiro boot**. Mudar o `.tf` não atualiza uma VM já criada até você **recriar** a instância ou aplicar mudanças **manualmente** no SO.

---

## 10. Desktop: cloud-init e RDP

### 10.1 Ideia central (estudo)

O desktop usa **imagem Ubuntu Server** (sem GUI no ISO). No primeiro boot, **`cloud-init`** executa `scripts/cloud-init-desktop.sh`, que instala **XFCE**, **LightDM** e **xrdp**, cria o usuário **`devuser`** e configura **UFW** (22 e 3389).

### 10.1a Double-check — o que fica pronto para RDP + XFCE (VPN)

| Camada | O que o script faz |
|--------|---------------------|
| **Pacotes** | XFCE (`xfce4`, `xfce4-session`, goodies), LightDM, **xrdp**, **xorgxrdp**, Xorg, **dbus-user-session** (sessão gráfica via RDP), utilitários de rede/desktop. |
| **Sessão RDP** | `/etc/xrdp/startwm.sh` inicia **XFCE** com `exec startxfce4` (limpa variáveis dbus comuns em sessão remota); `devuser` recebe **`.xsession`** (`xfce4-session`) e **`.Xclients`** (`startxfce4`). |
| **Serviços systemd** | `xrdp` e **xrdp-sesman** habilitados e reiniciados (ambos são necessários para login RDP). |
| **Polkit** | Regras para **colord** (evita bloqueios / tela cinza em sessão X remota em Ubuntu 20.04+). |
| **TLS / grupo** | Usuário de sistema `xrdp` no grupo **ssl-cert** quando o grupo existe. |
| **Firewall na VM** | UFW liberando **22/tcp** e **3389/tcp**. |
| **Rede OCI** | NSG + Security List do desktop já liberam **3389** a partir de `vpn_subnet_cidr` e `openvpn_client_cidr` (tráfego originado na VPN ou no pool OpenVPN). |
| **Conclusão** | Arquivo **`/opt/.instance-desktop-rdp-ready`** e logs de verificação (`xrdp` ativo, porta **3389** em escuta). |

**Quem pode conectar no RDP:** máquinas que apareçam para o NSG como origem na subnet da VPN ou no CIDR do pool OpenVPN — em geral, **notebook com VPN ligada** ao servidor OpenVPN.

### 10.2 Por que `user_data` é um script único (e não MIME multipart)?

**Problema no primeiro boot:** o **cloud-init** padrão e o **unattended-upgrades** podem usar o **apt** ao mesmo tempo que o seu script — **disputa pelo lock** (`Could not get lock`).

**Tentativa com MIME multipart** (`#cloud-config` com `package_update: false` + parte `text/x-shellscript`): em **imagens Oracle / cloud-init recente**, o handler **`ShellScriptPartHandler` pode falhar** para a parte shell. O sintoma é `cloud-init status: done` em **poucos segundos**, aviso no log tipo *Failed calling handler ShellScriptPartHandler*, e **nada** de XFCE/xrdp instalado — exatamente o que você quer evitar.

**Solução adotada:** um **único** `cloud-init-desktop.sh` em `user_data` (base64). No **início** do script:

- paramos **unattended-upgrades** e os timers **apt-daily**;
- **esperamos** a fila do apt liberar (com logs).

Assim reduzimos o lock **sem** depender de multipart. O restante do script:

- instala stack gráfica + **xrdp** + **xorgxrdp** + **dbus-user-session**, configura **xrdp-sesman**, **startwm.sh**, `.xsession` / `.Xclients` e polkit (**colord**);
- habilita **UFW**;
- **não** exige reboot obrigatório para o xrdp subir;
- cria **`/opt/.instance-desktop-rdp-ready`** e roda verificação de serviço/porta quando termina com sucesso.

**SSH:** usuário da imagem (ex.: **`ubuntu`**). **RDP:** **`devuser`** e senha no script (**altere** em ambientes reais).

### 10.3 Se o primeiro boot do desktop falhar

O caminho suportado é **sempre o cloud-init** com o **`cloud-init-desktop.sh` atual** no `user_data` (script único em base64).

1. **Preferencial:** ajuste o Terraform se precisar, depois **recrie** a instância desktop para reaplicar o `user_data` (ex.: `terraform apply -replace=oci_core_instance.desktop` — confira o nome do recurso no seu state).
2. **Alternativa avançada:** com SSH na VM, copie o conteúdo de **`scripts/cloud-init-desktop.sh`** do repositório, grave em um arquivo **com finais de linha Unix (LF)** e execute com `sudo bash` (é o mesmo script do primeiro boot). Se o arquivo passou pelo Windows e aparecer `^M` / `bad interpreter`, use: `sed -i 's/\r$//' ./cloud-init-desktop.sh` antes de rodar.

Não há script separado de “recover” no repositório — a manutenção concentra-se em **`cloud-init-desktop.sh`**.

#### Anexo: trechos em shell (referência; a fonte é `cloud-init-desktop.sh`)

O procedimento completo (polkit, verificação final, etc.) está só em **`scripts/cloud-init-desktop.sh`**. Abaixo, um **subconjunto** para estudo ou teste manual — use como `root`/`sudo` só se souber o efeito de cada comando:

```bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
apt-get install -y xorg dbus-x11 dbus-user-session xfce4 xfce4-goodies xfce4-session lightdm xrdp xorgxrdp xserver-xorg-core xserver-xorg-legacy
adduser --disabled-password --gecos "" devuser 2>/dev/null || true
echo 'devuser:Pass123' | chpasswd
usermod -aG sudo devuser
cat > /etc/xrdp/startwm.sh << 'EOF'
#!/bin/sh
. /etc/profile 2>/dev/null
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
exec startxfce4
EOF
chmod +x /etc/xrdp/startwm.sh
echo xfce4-session > /home/devuser/.xsession && chmod +x /home/devuser/.xsession && chown devuser:devuser /home/devuser/.xsession
echo startxfce4 > /home/devuser/.Xclients && chmod +x /home/devuser/.Xclients && chown devuser:devuser /home/devuser/.Xclients
getent group ssl-cert >/dev/null && usermod -a -G ssl-cert xrdp 2>/dev/null || true
systemctl enable --now xrdp xrdp-sesman
ufw allow 22/tcp && ufw allow 3389/tcp && ufw --force enable
```

Valide: `systemctl is-active xrdp xrdp-sesman` e `ss -tlnp | grep 3389`; RDP com usuário **devuser**.

---

## 11. Resolução de problemas

### 11.1 OpenVPN

| Sintoma | O que verificar |
|---------|------------------|
| VPN não conecta | NSG/SL da subnet VPN: UDP na `openvpn_port`; `ufw` no servidor; serviço `openvpn-server@server` ou `openvpn@server`. |
| VPN conecta mas não alcança o desktop | Rota no cliente para `vcn_cidr`; `openvpn_client_cidr` e regras do desktop; cloud-init do desktop concluído. |
| Não aparece `.ovpn` | Aguardar cloud-init; `/var/log/cloud-init-output.log` na VM VPN. |
| Novo cliente inválido | Menu em `/opt`, opção 1; conferir `.ovpn` completo e porta em `server.conf`. |

### 11.2 Desktop / RDP

| Sintoma | O que verificar |
|---------|------------------|
| `cloud-init status: done` rápido mas **sem** xrdp / log com `ShellScriptPartHandler` | Provável **multipart** antigo que não executou a parte shell — use **`user_data` só com** `cloud-init-desktop.sh` (commit atual) e **recrie** a VM; ou rode o script manualmente (§10.3). |
| `cloud-init status: error` e sem pacotes xrdp | **Recriar** a instância desktop com `cloud-init-desktop.sh` atual ou executar o mesmo script na mão (§10.3). |
| Porta 3389 fechada | `systemctl status xrdp`; `ss -tlnp \| grep 3389`; UFW; NSG (mesmos CIDRs que SSH se o cliente é o mesmo). |
| Cliente Windows bloqueia RDP | Algumas redes bloqueiam **saída** TCP 3389 mas não 22 — testar `Test-NetConnection -Port 3389` do PC. |

---

## 12. Consistência e limitações

- **`openvpn_client_cidr`** deve refletir o pool real do OpenVPN (padrão no script **10.8.0.0/24**).
- **State / renomeações de recursos**: mudanças podem exigir `terraform state mv` ou recriação.
- **Shapes Flex**: `shape_config` só quando o nome do shape contém `"Flex"`.
- **Região**: `oci_core_services` filtra pela região do provider; valide o *plan* em regiões novas.

---

## 13. Segurança

- Restrinja `vpn_ssh_ingress_cidr` e `openvpn_udp_ingress_cidr` (evite `0.0.0.0/0` em produção se possível).
- Altere senhas e usuários em `cloud-init-desktop.sh` antes de ambientes reais.
- Use `extra_admin_cidrs` com parcimônia no NSG do desktop.
- Alinhe **defined_tags** à política da tenancy.

---

## 14. Autoavaliação (checklist de estudo)

Tente responder **sem** olhar as seções anteriores. Depois confira o gabarito sugestivo abaixo.

1. Por que o desktop usa **NAT Gateway** em vez de IP público?
2. Qual a diferença entre tráfego para **internet** e tráfego para **Oracle Services Network** nesta VCN?
3. O que é **`openvpn_client_cidr`** e o que acontece se ele não bater com o pool do servidor OpenVPN?
4. Como o projeto **reduz o lock do apt** no primeiro boot do desktop **sem** usar MIME multipart?
5. Por que SSH e RDP podem usar **usuários diferentes** (`ubuntu` vs `devuser`)?
6. Por que você **não** deve tentar RDP no desktop **logo após** o `terraform apply` terminar no seu terminal?

<details>
<summary><strong>Gabarito sugestivo</strong> (clique para expandir)</summary>

1. **NAT:** o desktop fica na subnet **privada** (sem IP público na VNIC). Para acessar a internet com origem nesse IP privado, o tráfego de saída passa pelo **NAT Gateway** (SNAT). Assim você não expõe o desktop diretamente na internet.
2. **Internet vs OSN:** tráfego para **0.0.0.0/0** (internet) sai pela rota para o **NAT Gateway**. Tráfego para prefixos da **Oracle Services Network** (repos, APIs geridas pela Oracle na região) usa o **Service Gateway**, sem sair pela internet pública — melhor custo e caminho privado aos serviços Oracle.
3. **`openvpn_client_cidr`:** CIDR dos IPs que os **clientes OpenVPN** recebem ao conectar (no script padrão, pool **10.8.0.0/24**). As regras do **desktop** liberam SSH/RDP a partir desse intervalo. Se o Terraform apontar para um CIDR **diferente** do pool real no servidor OpenVPN, o firewall na nuvem pode **bloquear** SSH/RDP mesmo com VPN ligada.
4. **Lock do apt:** no início de `cloud-init-desktop.sh` paramos **unattended-upgrades** e timers **apt-daily** e **esperamos** até o apt ficar livre, antes do primeiro `apt-get update`. Não usamos multipart na OCI porque a parte shell pode falhar no handler e o primeiro boot “terminar” sem instalar nada.
5. **Dois usuários:** a imagem Ubuntu na OCI já vem com usuário **`ubuntu`** (chave SSH no `metadata`). O **cloud-init** cria **`devuser`** para sessão gráfica via **xrdp** (senha definida no script). São **papéis diferentes**: administração SSH típica vs. login no ambiente XFCE pelo RDP.
6. **Apply ≠ SO pronto:** o Terraform só **cria** a VM; o **primeiro boot** ainda roda `apt`, instala XFCE/xrdp etc. Isso leva **muitos minutos**. Se você tentar RDP antes do **cloud-init** concluir (`status: done`), o serviço pode nem estar instalado ou escutando na porta 3389.

</details>

---

## 15. Referências

- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [VCN, subnets, gateways](https://docs.oracle.com/iaas/Content/Network/Concepts/overview.htm)
- Detalhes de variáveis: `variables.tf`
