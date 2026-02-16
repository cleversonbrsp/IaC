# PostgreSQL + OpenVPN (psql)

Stack única: compartment, configuração PostgreSQL, rede (VCN + subnet DB + subnet VPN), DB system e instância OpenVPN. **Sempre executar Terraform a partir deste diretório** (`psql/`).

## Ordem de criação (garantida por dependências)

1. **compartment.tf** – Compartment `psql_hot_cold_lab`
2. **configuration.tf** – Configuração PostgreSQL (shape, overrides)
3. **network.tf** – VCN, subnet do DB (10.0.10.0/24), security list, NSG (5432/22 da VCN)
4. **network_ovpn.tf** – Subnet VPN (10.0.20.0/24), security list da VPN
5. **psql.tf** – DB system (depende da subnet VPN para ordem correta)
6. **instance_ovpn.tf** – Instância OpenVPN + NSG + IP público reservado (imagem em `variables.tf`/`terraform.tfvars`)

A rede do DB permite tráfego de toda a VCN (10.0.0.0/16), incluindo a subnet VPN (10.0.20.0/24), para que o tráfego da instância OpenVPN (e clientes via VPN) alcance o PostgreSQL.

## Uso

```bash
cp terraform.tfvars.example terraform.tfvars
# Editar: parent_compartment_id, primary_db_endpoint_private_ip, availability_domain. SSH: ~/.ssh/instance-oci.pub (privada: instance-oci.key)
terraform init
terraform plan
terraform apply
```

Após o apply, aguarde o cloud-init terminar na VM (OpenVPN). Log: `ssh ubuntu@<vpn_public_ip> 'sudo cat /var/log/openvpn-install.log'`.

## Acesso ao DB via VPN

1. Após o apply: `terraform output vpn_public_ip`
2. Copiar o cliente .ovpn da instância: `scp ubuntu@<vpn_public_ip>:/etc/openvpn/client-configs/files/openvpn-config.ovpn .`
3. Se no .ovpn estiver `remote CHANGE_ME 1194`, trocar por `remote <vpn_public_ip> 1194`
4. Conectar com o cliente OpenVPN; acessar o DB em `primary_endpoint_private_ip:5432` (ex.: 10.0.10.10:5432)

## Estrutura

- **psql/** – Todos os `.tf`; executar `terraform` somente aqui.
- **psql/scripts/** – `openvpn-ubuntu-install.sh` (instalação via cloud-init); `openvpn-opt-menu.sh` (cópia do menu para `/opt` em VMs já existentes).

**Se a instância VPN foi criada antes do script gravar o menu em `/opt`**, copie o menu para a VM e coloque em `/opt`:
```bash
scp scripts/openvpn-opt-menu.sh ubuntu@<vpn_public_ip>:/tmp/
# Na VM: sudo mv /tmp/openvpn-opt-menu.sh /opt/openvpn-ubuntu-install.sh && sudo chmod +x /opt/openvpn-ubuntu-install.sh
```
Depois, na VM: `sudo /opt/openvpn-ubuntu-install.sh` para Add client / Revoke / Remove / Exit.

**Se o OpenVPN não foi instalado pelo cloud-init** (ex.: não existem `/etc/openvpn/server/server.conf` e `/etc/openvpn/ca.crt`), rode a instalação manual na VM:
```bash
# Na sua máquina
scp -i ~/.ssh/instance-oci.key scripts/openvpn-ubuntu-install.sh ubuntu@<vpn_public_ip>:/tmp/

# Na VM (SSH)
export db_subnet_cidr=10.0.10.0/24
sudo bash /tmp/openvpn-ubuntu-install.sh
```
Depois: `sudo systemctl status openvpn@server` e `sudo /opt/openvpn-ubuntu-install.sh` para o menu.
