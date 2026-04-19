# Instance desktop na OCI (Terraform)

Stack que cria um **compartment**, uma **VCN** com **OpenVPN** (subnet pública + IP público) e um **Ubuntu desktop** (subnet privada, sem IP público), com saída à internet via **NAT** e acesso a serviços OCI via **Service Gateway**.

---

## Índice

1. [Objetivo](#1-objetivo)
2. [O que é criado](#2-o-que-é-criado)
3. [Arquitetura de rede](#3-arquitetura-de-rede)
4. [Estrutura de ficheiros no repositório](#4-estrutura-de-ficheiros-no-repositório)
5. [Pré-requisitos](#5-pré-requisitos)
6. [Configuração (`terraform.tfvars`)](#6-configuração-terraformtfvars)
7. [Comandos Terraform](#7-comandos-terraform)
8. [Outputs](#8-outputs)
9. [Fluxo de acesso: VPN → desktop](#9-fluxo-de-acesso-vpn--desktop)
10. [OpenVPN — documentação completa](#10-openvpn--documentação-completa)
    - [10.1 Instalação via user_data](#101-instalação-via-user_data)
    - [10.2 Ficheiros no servidor Linux](#102-ficheiros-no-servidor-linux)
    - [10.3 Primeiro perfil ovpn](#103-primeiro-perfil-ovpn)
    - [10.4 Perfis adicionais em /opt](#104-perfis-adicionais-em-opt)
    - [10.5 Pool 10.8.0.0/24 e openvpn_client_cidr](#105-pool-1080024-e-openvpn_client_cidr)
    - [10.6 Paridade com oke-crs](#106-paridade-com-oke-crs)
    - [10.7 VMs já existentes e atualização do script](#107-vms-já-existentes-e-atualização-do-script)
    - [10.8 Resolução de problemas](#108-resolução-de-problemas)
11. [Instância desktop (XFCE, XRDP, `cloud-init`)](#11-instância-desktop-xfce-xrdp-cloud-init)
12. [Consistência e limitações](#12-consistência-e-limitações)
13. [Segurança](#13-segurança)
14. [Referências](#14-referências)

---

## 1. Objetivo

- **Desktop** acessível por **SSH (22)** e **RDP (3389)** apenas a partir de tráfego que venha da **subnet VPN** ou do **pool de clientes OpenVPN** (regras em NSG + Security List).
- **Saída** do desktop para a internet: **NAT Gateway**; para **Oracle Services Network**: **Service Gateway**.
- **Servidor OpenVPN** exposto na internet apenas nas portas configuradas (**UDP** na `openvpn_port` e **SSH (22)** para administração, conforme `vpn_ssh_ingress_cidr` e `openvpn_udp_ingress_cidr`).

---

## 2. O que é criado

| Camada | Recursos principais |
|--------|---------------------|
| **Identity** | `oci_identity_compartment` (região *home*) + espera (`time_sleep`) para propagação |
| **Rede** | VCN, Internet Gateway, NAT Gateway, Service Gateway, 2 route tables, 2 subnets, Security Lists, NSG |
| **Compute** | 2× `oci_core_instance`: **OpenVPN** (subnet pública) e **desktop** (subnet privada) |
| **Dados** | `oci_core_services` (OSN para o SGW), data sources de VNIC para outputs |

---

## 3. Arquitetura de rede

```text
                    Internet
                        │
                        ▼
              ┌─────────────────┐
              │ Internet Gateway │  ◄── subnet VPN (IP público no servidor OpenVPN)
              └────────┬────────┘
                       │
    ┌──────────────────┴──────────────────┐
    │                 VCN (ex.: /16)        │
    │  ┌─────────────────────────────┐    │
    │  │ Subnet VPN (pública / IGW)  │    │
    │  │   • Instância OpenVPN       │    │
    │  └─────────────────────────────┘    │
    │  ┌─────────────────────────────┐    │
    │  │ Subnet privada (NAT+SGW)    │    │
    │  │   • Desktop (sem IP público)│    │
    │  └─────────────────────────────┘    │
    └─────────────────────────────────────┘
```

- **Subnet privada**: `prohibit_public_ip_on_vnic = true`; rotas: `0.0.0.0/0` → NAT; OSN → Service Gateway.
- **Subnet VPN**: IP público permitido; rota default → Internet Gateway.

---

## 4. Estrutura de ficheiros no repositório

| Ficheiro | Função |
|----------|--------|
| `versions.tf` | Versão mínima do Terraform e *providers* exigidos |
| `providers.tf` | Provider `oci` (workload) e `oci.home` (Identity na home region) |
| `data.tf` | Data source da Oracle Services Network (Service Gateway) |
| `locals.tf` | Valores derivados: compartment, AD, imagens, OSN |
| `compartments.tf` | Compartment filho + `time_sleep` pós-compartment |
| `network.tf` | VCN, gateways, route tables, subnets, SL, NSG, regras |
| `compute_vpn.tf` | Instância VPN; `user_data` = só `templatefile(openvpn-ubuntu-install.sh)` (modelo **wln/psql**: menu em `/opt`) |
| `compute_desktop.tf` | Instância desktop + leitura da VNIC |
| `variables.tf` | Variáveis de entrada |
| `outputs.tf` | Saídas (IPs, OCIDs, comandos sugeridos) |
| `scripts/cloud-init-desktop.sh` | Primeiro boot do desktop (`user_data`: XFCE, XRDP, aplicações) |
| `scripts/openvpn-ubuntu-install.sh` | Instalação + gravação de `/opt/openvpn-ubuntu-install.sh` (menu add/revoke/remove), alinhado a `dbsystems/wln/psql/scripts` |
| `terraform.tfvars.example` | Modelo de valores (copiar para `terraform.tfvars`) |

---

## 5. Pré-requisitos

- Terraform **>= 1.3.0** (definido em `versions.tf`).
- CLI OCI configurada: `~/.oci/config` com o profile usado em `oci_config_profile`.
- **Home region** da tenancy correta em `oci_home_region` (Identity/compartment).
- **Availability Domain** válido para a região de workload em `availability_domain_name` (formato típico: `PREFIXO:REGION-AD-N`).
- Chave **SSH pública** acessível no caminho definido em `ssh_public_key_path`.

---

## 6. Configuração (`terraform.tfvars`)

1. Copie o exemplo: `cp terraform.tfvars.example terraform.tfvars`
2. Preencha no mínimo:
   - `oci_home_region`, `parent_compartment_id`
   - `availability_domain_name`
   - `instance_image_id` (e opcionalmente `vpn_image_id` se for imagem diferente da VPN; vazio = mesma que o desktop)
   - `ssh_public_key_path` (e `ssh_private_key_path` para os outputs de SSH)
3. Ajuste CIDRs para **não se sobreporem** dentro da mesma VCN:
   - `vcn_cidr` (/16)
   - `private_subnet_cidr` e `vpn_subnet_cidr` (/24 típicos, contidos na VCN)

Variáveis úteis da VPN (ver `variables.tf`): `openvpn_port`, `vpn_ssh_ingress_cidr`, `openvpn_udp_ingress_cidr`, `vpn_subnet_cidr`, `openvpn_client_cidr`, `vpn_instance_*`, `extra_admin_cidrs`.

O ficheiro `terraform.tfvars` costuma estar no `.gitignore` do repositório pai: **não commite** segredos nem OCIDs sensíveis.

---

## 7. Comandos Terraform

```bash
cd /caminho/para/instance-desktop
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Inspeção pós-apply:

```bash
terraform output
terraform output -raw vpn_public_ip
```

---

## 8. Outputs

| Output | Uso |
|--------|-----|
| `vpn_public_ip` | IP público do servidor OpenVPN (UDP na `openvpn_port`) |
| `vpn_ssh_cmd` | SSH para administrar a VM da VPN |
| `openvpn_menu_cmd` | Comando a correr **no servidor**: `sudo bash /opt/openvpn-ubuntu-install.sh` (menu interativo) |
| `desktop_private_ip` | IP privado do desktop (sem rota direta da internet) |
| `ssh_cmd` | SSH ao desktop **após** VPN (utilizador `cloud_init_user`, ex. `ubuntu`) |
| `rdp_hint` | `IP_PRIVADO:3389` para cliente RDP **após** VPN |
| `vpn_access_note` | Lembrete sobre CIDRs e regras |

---

## 9. Fluxo de acesso: VPN → desktop

1. Cliente VPN liga ao **IP público** do servidor OpenVPN (UDP na `openvpn_port`).
2. O servidor publica rota para o **`vcn_cidr`** no perfil do cliente (split tunnel: só esse intervalo através do túnel, salvo alteração manual do `.ovpn`).
3. Com a VPN ativa, o tráfego para o **IP privado** do desktop origina-se da subnet VPN ou do pool `10.8.0.0/24`, alinhado com as regras NSG/SL.
4. **RDP** e **SSH** ao desktop usam esse IP privado; não existe IP público na VNIC do desktop.

---

## 10. OpenVPN — documentação completa

### 10.1 Instalação via user_data

- O Terraform só passa **`templatefile("scripts/openvpn-ubuntu-install.sh", { vcn_cidr, openvpn_port })`** em `compute_vpn.tf` (sem `join` de outros ficheiros), no mesmo estilo que **`IaC/terraform/oci/dbsystems/wln/psql`**.
- No **fim** da instalação inicial, o script grava **`/opt/openvpn-ubuntu-install.sh`**: um menu interactivo (adicionar cliente, revogar, remover OpenVPN). A porta `remote` no `.ovpn` gerado pelo menu é alinhada com `openvpn_port` via `sed` (como no wln/psql).
- Se o serviço OpenVPN **já estiver activo** (re-execução do script), o mesmo ficheiro mostra primeiro o menu em vez de reinstalar.
- Imagem suportada: **Ubuntu** 20.04 / 22.04 / 24.04.

### 10.2 Ficheiros no servidor Linux

| Caminho | Descrição |
|---------|-----------|
| `/etc/openvpn/easy-rsa/` | PKI Easy-RSA (CA, servidor, clientes) |
| `/etc/openvpn/server/server.conf` | Configuração do *daemon* OpenVPN |
| `/etc/openvpn/client-configs/base.conf` | Base do primeiro cliente (`remote` = IP público no install) |
| `/etc/openvpn/client-configs/files/` | Ficheiros `.ovpn` (inclui `openvpn-config.ovpn` e os criados pelo menu) |
| **`/opt/openvpn-ubuntu-install.sh`** | Menu interactivo (add / revoke / remove); **comando:** `sudo bash /opt/openvpn-ubuntu-install.sh` |

### 10.3 Primeiro perfil `.ovpn`

- Nome fixo no instalador: **`openvpn-config`**.
- Caminho no servidor: **`/etc/openvpn/client-configs/files/openvpn-config.ovpn`**.
- O arquivo só é legível como root; no seu computador use `sudo cat` via SSH (não precisa preparar `/tmp` no servidor).

**Com IP do Terraform** (rode `terraform output` no diretório do stack):

```bash
mkdir -p /home/cleverson/ovpn-clients
VPN_IP="$(terraform output -raw vpn_public_ip)"
ssh -i ~/.ssh/sua_chave.pem ubuntu@"$VPN_IP" \
  'sudo cat /etc/openvpn/client-configs/files/openvpn-config.ovpn' \
  > /home/cleverson/ovpn-clients/openvpn-config.ovpn
```

**Exemplo com IP em variável e chave `instance-oci.key`** (defina `VPN_IP` com o IP público da VPN, ex.: saída de `terraform output -raw vpn_public_ip`):

```bash
mkdir -p /home/cleverson/ovpn-clients
VPN_IP="COLOQUE_AQUI_O_IP_PUBLICO"   # ex.: saída de terraform output -raw vpn_public_ip
ssh -i ~/.ssh/instance-oci.key ubuntu@"$VPN_IP" \
  'sudo cat /etc/openvpn/client-configs/files/openvpn-config.ovpn' \
  > /home/cleverson/ovpn-clients/openvpn-config.ovpn
```

Ajuste o usuário (`ubuntu`) se `cloud_init_user` for outro e o caminho da chave (`-i`) conforme o seu ambiente.

### 10.4 Perfis adicionais e menu em /opt

No servidor VPN (SSH), use o **mesmo script** que no stack PostgreSQL/wln:

```bash
sudo bash /opt/openvpn-ubuntu-install.sh
```

- Escolha **1) Add a new client**, indique o nome (ex. `mydesk`); o `.ovpn` fica em `/etc/openvpn/client-configs/files/<nome>.ovpn`.
- **2)** revoga certificado; **3)** remove o OpenVPN e apaga `/opt/openvpn-ubuntu-install.sh`.
- Não é necessário reiniciar o *daemon* para novos clientes (mesma CA).

**Nota:** não use `openvpn-add-client` nem symlink em `/usr/local/bin` — esse modelo foi substituído por este menu único em `/opt`.

### 10.5 Pool 10.8.0.0/24 e openvpn_client_cidr

- O instalador define no servidor a linha `server 10.8.0.0 255.255.255.0` (pool de clientes).
- As regras do **desktop** no Terraform usam `openvpn_client_cidr` (default **`10.8.0.0/24`**) para permitir SSH/RDP a partir de endereços desse pool.
- Se alterar o pool no `openvpn-ubuntu-install.sh`, deve atualizar **`openvpn_client_cidr`** e as regras de firewall no SO (iptables no script) em conjunto — caso contrário, o desktop ou o encaminhamento podem deixar de funcionar.

### 10.6 Paridade com wln/psql e oke-crs

- **Referência principal:** `IaC/terraform/oci/dbsystems/wln/psql/scripts/openvpn-ubuntu-install.sh` — grava `/opt/openvpn-ubuntu-install.sh` no final.
- **`oke-crs`** pode continuar com o seu próprio `user_data`; para o mesmo comportamento de menu em `/opt`, alinhe o script ou partilhe o ficheiro do wln.

### 10.7 VMs já existentes e atualização do script

- O **`user_data` / cloud-init** corre em geral **só no primeiro boot**. Alterações ao Terraform que mudem apenas o script **não** são aplicadas automaticamente numa VM antiga até que a instância seja **recriada** ou o procedimento de atualização seja feito **manualmente** no servidor (copiar novo script para `/opt`, etc.).
- Para forçar recriação (destrutivo): `terraform taint` no recurso `oci_core_instance.vpn` ou alteração que obrigue novo `user_data` (dependendo da política do provider).

### 10.8 Resolução de problemas

| Sintoma | Verificação |
|---------|-------------|
| VPN não liga | Security List / NSG da subnet VPN: UDP na `openvpn_port`; SG local (`ufw`) no servidor; serviço `openvpn-server@server` ou `openvpn@server` ativo. |
| VPN liga mas não alcança o desktop | Rota no cliente para `vcn_cidr`; `openvpn_client_cidr` e regras do desktop; cloud-init do desktop terminou (RDP/SSH no SO). |
| Sem ficheiro `.ovpn` | Esperar fim do cloud-init; ver `/var/log/cloud-init-output.log` no servidor VPN. |
| Novo cliente não funciona | Correr `sudo bash /opt/openvpn-ubuntu-install.sh`, opção 1; confirmar `.ovpn` completo e porta no `server.conf`. |

---

## 11. Instância desktop (XFCE, XRDP, `cloud-init`)

- Ficheiro: **`scripts/cloud-init-desktop.sh`**, referenciado em `compute_desktop.tf` como `user_data` em **base64**.
- Ações principais: `apt upgrade`, instalação de **XFCE**, **LightDM**, **XRDP**, criação do utilizador **`devuser`** com password definida no script (altere em produção), instalação de aplicações (Firefox, VS Code, *snap*, etc.), **UFW** com portas 22 e 3389.
- **Utilizador SSH** na OCI costuma ser o da imagem (ex. **`ubuntu`**); o **RDP** no script está preparado para **`devuser`**.
- O desktop **não** tem IP público: RDP/SSH passam pela VPN até ao IP privado.

---

## 12. Consistência e limitações

- **`openvpn_client_cidr`** deve refletir o pool real do servidor OpenVPN (hoje **`10.8.0.0/24`** no script).
- **State / renomeação de recursos**: mudanças de endereços no state podem exigir `terraform state mv` ou recriação.
- **Shapes Flex**: `shape_config` só é aplicado quando o nome do shape contém `"Flex"`.
- **Região**: o *data source* `oci_core_services` filtra o serviço OSN pelo nome da região do provider; em regiões não testadas, valide o *plan*.

---

## 13. Segurança

- Restrinja `vpn_ssh_ingress_cidr` e `openvpn_udp_ingress_cidr` (não deixe `0.0.0.0/0` em produção se puder evitar).
- Altere passwords e utilizadores em `cloud-init-desktop.sh` antes de ambientes reais.
- Use `extra_admin_cidrs` com parcimônia no NSG do desktop.
- Revise **defined_tags** conforme política da tenancy.

---

## 14. Referências

- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [VCN, subnets, gateways](https://docs.oracle.com/iaas/Content/Network/Concepts/overview.htm)
- Variáveis detalhadas: `variables.tf`.
