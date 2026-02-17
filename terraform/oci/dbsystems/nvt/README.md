# NVT – PostgreSQL + OpenVPN (psql)

Stack única no subdiretório `psql/`: compartment, configuração PostgreSQL, rede (VCN + subnet DB + subnet VPN), **dois** DB Systems (HOT e COLD) e instância OpenVPN. **Sempre executar Terraform a partir de `psql/`.**

---

## Visão geral

| Componente | Descrição |
|------------|-----------|
| **Compartment** | `psql_hot_cold_lab` – criado na **home region** do tenancy (ex.: GRU). |
| **Rede** | Uma VCN; subnet privada para PostgreSQL; subnet com IP público para OpenVPN. |
| **PostgreSQL** | Uma **configuration** compartilhada + dois **DB Systems**: HOT (produção) e COLD (archive), na região definida em `oci_region`. |
| **OpenVPN** | Uma instância (ex.: Ubuntu) na subnet VPN; acesso ao DB apenas via VPN. |

---

## Regiões

- **Home region** (`home_region`, ex.: `sa-saopaulo-1` – GRU): usada **apenas** para criar/alterar o **compartment** (Identity exige home region).
- **Região de recursos** (`oci_region`, ex.: `us-ashburn-1`): onde são criados VCN, subnets, DB Systems, configuration e instância OpenVPN.

Após criar o compartment, o módulo espera **90 segundos** (`time_sleep`) antes de criar VCN e configuration na região de recursos, para evitar 404 por propagação do compartment.

---

## Ordem de criação (dependências)

1. **compartment.tf** – Compartment `psql_hot_cold_lab` (provider `oci.home`, home region).
2. **main.tf** – `time_sleep.wait_compartment_propagation` (90s).
3. **network.tf** – VCN, IGW, subnet DB (privada), security list DB, NSG DB, route table VPN, subnet VPN, security list VPN, NSG VPN.
4. **psql_conf.tf** – Configuração PostgreSQL (shape E5.Flex, overrides; depende do `time_sleep`).
5. **psql.tf** – DB System HOT e DB System COLD (dependem da subnet VPN para ordem correta).
6. **instance_ovpn.tf** – Instância OpenVPN (cloud-init com script em `scripts/`).

A subnet do DB aceita tráfego de **toda a VCN** (incluindo a subnet VPN), para que clientes via OpenVPN alcancem o PostgreSQL na porta 5432.

---

## DB Systems HOT e COLD

| | HOT | COLD |
|---|-----|------|
| **Nome (ex.)** | `pg-hot-prd` | `pg-cold-archive` |
| **Uso** | Produção | Archive / cold |
| **Backup** | Habilitado (ex.: MONTHLY, 7 dias) | Desabilitado (`kind = "NONE"`) |
| **Variáveis** | `db_system_display_name`, `instance_memory_size_in_gbs`, `instance_ocpu_count`, `primary_db_endpoint_private_ip`, `backup_*` | `cold_*` (display_name, memory, ocpu, IP, backup_kind, etc.) |

Ambos usam a mesma **configuration** (`oci_psql_configuration.psql_config`). A configuration usa shape **VM.Standard.E5.Flex** e, na OCI, exige **memória entre 16 e 64 GB**; o código usa `max(16, instance_memory_size_in_gbs, cold_instance_memory_size_in_gbs)` para respeitar esse mínimo. Os DB Systems podem usar menos memória/OCPU no recurso, conforme variáveis no `terraform.tfvars`.

---

## Configuração PostgreSQL (psql_conf.tf)

- **Shape**: `VM.Standard.E5.Flex` (fixo na configuration).
- **DB systems**: shape definido em `db_system_shape` (ex.: `PostgreSQL.VM.Standard.E5.Flex`). E4 pode não estar habilitado em alguns compartments/regiões.
- **Override**: `log_connections = 1`.
- **Memória na configuration**: mín. 16 GB (E5.Flex); valor efetivo = `max(16, instance_memory_size_in_gbs, cold_instance_memory_size_in_gbs)`.

---

## Rede

- **VCN**: CIDR configurável (ex.: `10.0.0.0/16`).
- **Subnet DB**: privada (`prohibit_public_ip_on_vnic = true`), ex.: `10.0.10.0/24`. Security list: 5432 e 22 a partir da VCN. NSG do PostgreSQL associado aos DB Systems.
- **Subnet VPN**: ex.: `10.0.20.0/24`, com rota para IGW; IP público na VNIC da instância OpenVPN. Security list: SSH do `ssh_allowed_cidr` e da própria subnet; 5432 do DB para referência. NSG: UDP (porta OpenVPN) e SSH.

---

## Uso

```bash
cd psql
cp terraform.tfvars.example terraform.tfvars   # se existir
# Editar terraform.tfvars: parent_compartment_id, oci_region, home_region, availability_domain,
#   primary_db_endpoint_private_ip, cold_primary_db_endpoint_private_ip, db_*, cold_*, rede, SSH, image_id, common_tags
terraform init
terraform plan
terraform apply
```

**OCI CLI**: o profile usado é `oci_config_profile` (ex.: `DEFAULT`). O arquivo `~/.oci/config` deve conter um bloco `[DEFAULT]` (ou o nome do profile) com a região correta.

Após o apply, aguarde o cloud-init na VM OpenVPN. Log sugerido: `ssh ubuntu@$(terraform output -raw vpn_public_ip) 'sudo cat /var/log/openvpn-install.log'`.

---

## Acesso ao DB via VPN

1. Obter IP da VPN: `terraform output vpn_public_ip`
2. Copiar o cliente .ovpn: `scp ubuntu@<vpn_public_ip>:/etc/openvpn/client-configs/files/openvpn-config.ovpn .`
3. Se no .ovpn estiver `remote CHANGE_ME 1194`, trocar por `remote <vpn_public_ip> 1194` (e porta se `openvpn_port` for diferente).
4. Conectar com cliente OpenVPN; acessar o DB em `primary_endpoint_private_ip:5432` (HOT) ou `cold_primary_endpoint_private_ip:5432` (COLD), ex.: `10.0.10.10` e `10.0.10.11`.

---

## Outputs

| Output | Descrição |
|--------|-----------|
| `compartment_id` | OCID do compartment usado. |
| `vcn_id`, `subnet_id`, `vpn_subnet_id` | Rede. |
| `psql_configuration_id` | Configuration compartilhada. |
| `db_system_id`, `db_system_display_name`, `state`, `primary_endpoint_private_ip` | HOT. |
| `db_system_cold_id`, `db_system_cold_display_name`, `cold_primary_endpoint_private_ip` | COLD. |
| `vpn_public_ip`, `ssh_connect` | Acesso à instância OpenVPN. |

---

## Destroy

A OCI **não permite apagar a configuration** enquanto existir DB System usando ela. Ordem recomendada:

1. Destruir os dois DB Systems:
   ```bash
   terraform destroy -target=oci_psql_db_system.postgresql_db_system -target=oci_psql_db_system.postgresql_db_system_cold
   ```
2. Esperar os DB Systems ficarem **TERMINATED** no Console (se necessário).
3. Destruir o resto (configuration, rede, compartment, etc.):
   ```bash
   terraform destroy
   ```

Não use `-target=oci_psql_configuration.psql_config` sozinho; destrua primeiro os DB Systems.

---

## Tags (defined_tags)

Todos os recursos taggáveis recebem `var.common_tags.defined_tags` (ex.: namespace `finops`). O namespace das tags deve existir no tenancy (Governance → Tag Namespaces). Recursos que recebem tags: compartment, VCN, IGW, subnets, route table, security lists, NSGs, configuration, ambos DB Systems, instância OpenVPN.

---

## Problemas comuns

| Erro / Situação | Causa / Solução |
|-----------------|------------------|
| `configuration file did not contain profile: default` | Profile em `terraform.tfvars` deve coincidir com um bloco em `~/.oci/config` (ex.: `DEFAULT` em maiúsculas). |
| `Please go to your home region GRU to execute CREATE, UPDATE and DELETE` (Identity) | Compartment deve ser criado na home region; o módulo usa `provider = oci.home` no compartment. |
| `404 NotAuthorizedOrNotFound` ao criar VCN ou Psql Configuration | Propagação do compartment; o `time_sleep` de 90s deve atenuar. Se persistir, aguardar mais e rodar `terraform apply` de novo ou conferir políticas IAM no compartment. |
| `E4 feature is not enabled at this time for compartment` | Shape E4 não habilitado no compartment/região; use `PostgreSQL.VM.Standard.E5.Flex` em `db_system_shape` (e configuration já usa E5). |
| `Invalid instanceMemorySizeInGBs: Specified value 8 is not in range [16, 64]` | Na **configuration**, E5.Flex exige 16–64 GB; o código usa `max(16, ...)` para memória. Os DB Systems podem usar 8 GB no recurso se a API permitir. |
| `Cannot delete DB Config ... as its being actively used by a DbSystem` | Destruir os DB Systems antes da configuration (ver **Destroy** acima). |

---

## Estrutura do diretório

```
nvt/
├── README.md                 # Este arquivo
└── psql/
    ├── main.tf                # Providers OCI (default + home), time_sleep, local compartment_id
    ├── compartment.tf         # Compartment psql_hot_cold_lab (provider home)
    ├── network.tf             # VCN, IGW, subnets DB/VPN, security lists, NSGs, route table
    ├── psql_conf.tf           # Configuração PostgreSQL (shape, overrides)
    ├── psql.tf                # DB System HOT e DB System COLD
    ├── instance_ovpn.tf       # Instância OpenVPN (user_data = script)
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars       # Valores (não versionar se tiver senha/chaves)
    ├── .gitignore
    └── scripts/
        ├── openvpn-ubuntu-install.sh   # Instalação OpenVPN (cloud-init / templatefile)
        └── openvpn-opt-menu.sh         # Cópia do menu para /opt em VMs já existentes
```

**Se a instância VPN foi criada antes do script gravar o menu em `/opt`**:
```bash
scp psql/scripts/openvpn-opt-menu.sh ubuntu@<vpn_public_ip>:/tmp/
# Na VM: sudo mv /tmp/openvpn-opt-menu.sh /opt/openvpn-ubuntu-install.sh && sudo chmod +x /opt/openvpn-ubuntu-install.sh
```
Depois, na VM: `sudo /opt/openvpn-ubuntu-install.sh` (Add client / Revoke / Remove / Exit).

**Se o OpenVPN não foi instalado pelo cloud-init** (ex.: não existem `/etc/openvpn/server/server.conf` e `/etc/openvpn/ca.crt`):
```bash
scp -i ~/.ssh/instance-oci.key psql/scripts/openvpn-ubuntu-install.sh ubuntu@<vpn_public_ip>:/tmp/
# Na VM: export db_subnet_cidr=10.0.10.0/24; sudo bash /tmp/openvpn-ubuntu-install.sh
```
Depois: `sudo systemctl status openvpn@server` e `sudo /opt/openvpn-ubuntu-install.sh` para o menu.
