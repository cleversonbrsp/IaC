#!/bin/bash
#
# OpenVPN — cloud-init + menu em /opt (modelo wln/psql).
# templatefile: vcn_cidr, openvpn_port
#
# Copyright (c) 2013 Nyr. Released under the MIT License.

if readlink /proc/$$/exe | grep -q "dash"; then
  echo 'This installer needs to be run with "bash", not "sh".'
  exit
fi

read -N 999999 -t 0.001

# --- Menu quando o serviço já está ativo (re-execução manual ou /opt) ---
if systemctl is-active --quiet openvpn-server@server 2>/dev/null || systemctl is-active --quiet openvpn@server 2>/dev/null; then
  echo "OpenVPN is already installed and running."
  echo
  echo "Select an option:"
  echo "   1) Add a new client"
  echo "   2) Revoke an existing client"
  echo "   3) Remove OpenVPN"
  echo "   4) Exit"
  read -p "Choose an option: " option

  case "$option" in
    1)
      read -p "Enter client name (e.g., mydesk): " CLIENT_NAME
      OVPN_PORT=$(grep -E '^port ' /etc/openvpn/server/server.conf 2>/dev/null | awk '{print $2}')
      OVPN_PORT=$${OVPN_PORT:-1194}
      cd /etc/openvpn/easy-rsa
      ./easyrsa --batch build-client-full "$CLIENT_NAME" nopass
      CLIENT_DIR="/etc/openvpn/client-configs"
      mkdir -p "$CLIENT_DIR/files"
      cp /etc/openvpn/easy-rsa/pki/ca.crt "$CLIENT_DIR/files/"
      cp "/etc/openvpn/easy-rsa/pki/issued/$${CLIENT_NAME}.crt" "$CLIENT_DIR/files/"
      cp "/etc/openvpn/easy-rsa/pki/private/$${CLIENT_NAME}.key" "$CLIENT_DIR/files/"
      cp /etc/openvpn/tc.key "$CLIENT_DIR/files/"
      ovpn_file="$CLIENT_DIR/files/$${CLIENT_NAME}.ovpn"
      cat > "$ovpn_file" <<EOF
client
dev tun
proto udp
remote $(curl -s ifconfig.me) $OVPN_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
ignore-unknown-option block-outside-dns
verb 3
<ca>
$(cat "$CLIENT_DIR/files/ca.crt")
</ca>
<cert>
$(cat "$CLIENT_DIR/files/$${CLIENT_NAME}.crt")
</cert>
<key>
$(cat "$CLIENT_DIR/files/$${CLIENT_NAME}.key")
</key>
<tls-crypt>
$(cat "$CLIENT_DIR/files/tc.key")
</tls-crypt>
EOF
      echo "Client configuration file created at: $ovpn_file"
      ;;
    2)
      echo "Select a client to revoke:"
      cd /etc/openvpn/easy-rsa
      echo "Listing existing client certificates:"
      for cert in pki/issued/*.crt; do
        [[ -f "$cert" ]] || continue
        client_name=$(basename "$cert" .crt)
        [[ "$client_name" == "server" ]] && continue
        echo "$client_name"
      done
      read -p "Enter the client name to revoke: " CLIENT_NAME
      ./easyrsa --batch revoke "$CLIENT_NAME"
      ./easyrsa gen-crl
      mkdir -p /etc/openvpn/server
      cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
      echo "Client $CLIENT_NAME has been revoked."
      ;;
    3)
      echo "Removing OpenVPN..."
      systemctl stop openvpn-server@server 2>/dev/null || true
      systemctl stop openvpn@server 2>/dev/null || true
      systemctl disable openvpn-server@server 2>/dev/null || true
      systemctl disable openvpn@server 2>/dev/null || true
      apt-get remove --purge -y openvpn easy-rsa
      rm -rf /etc/openvpn
      rm -f /opt/openvpn-ubuntu-install.sh
      echo "OpenVPN has been removed."
      ;;
    4)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid option. Exiting..."
      exit 1
      ;;
  esac
  exit 0
fi

# --- Instalação inicial (cloud-init) ---

LOG="/var/log/openvpn-install.log"
log() { echo "$(date -Iseconds) $*" >> "$LOG"; }

if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

if [[ -e /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  OS=$ID
  VERSION_ID=$VERSION_ID
else
  echo "Cannot detect OS. Unsupported."
  exit 1
fi

if [[ $OS == "ubuntu" && ( $VERSION_ID == "20.04" || $VERSION_ID == "22.04" || $VERSION_ID == "24.04" ) ]]; then
  :
else
  echo "Unsupported: $OS $VERSION_ID. Supports Ubuntu 20.04, 22.04, 24.04."
  exit 1
fi

log "Starting OpenVPN install"
apt-get update -qq || { sleep 10; apt-get update -qq; }
apt-get install -y openvpn easy-rsa wget curl iptables-persistent || { sleep 15; apt-get install -y openvpn easy-rsa wget curl iptables-persistent; }
log "Packages installed"

echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/^#net.ipv4.ip_forward=1/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
sysctl -p

public_ip=$(curl -s ifconfig.me)
echo "Public IP: $public_ip"
port="${openvpn_port}"
[ -z "$port" ] || [ "$port" = "0" ] && port=1194
protocol="udp"
dns_server="1.1.1.1 8.8.8.8"

VCN_CIDR="${vcn_cidr}"
VCN_NET=$(echo "$VCN_CIDR" | cut -d/ -f1)
VCN_MASK_BITS=$(echo "$VCN_CIDR" | cut -d/ -f2)
case "$VCN_MASK_BITS" in
  24) VCN_MASK="255.255.255.0" ;;
  16) VCN_MASK="255.255.0.0" ;;
  8) VCN_MASK="255.0.0.0" ;;
  *) VCN_MASK="255.255.0.0" ;;
esac

EASY_RSA_DIR=/etc/openvpn/easy-rsa
[[ ! -d "$EASY_RSA_DIR" ]] && { mkdir -p "$EASY_RSA_DIR" && ln -s /usr/share/easy-rsa/* "$EASY_RSA_DIR/"; }

cd "$EASY_RSA_DIR" || exit 1
cp vars vars.bak 2>/dev/null || true
cat > vars << 'EOVARS'
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "California"
set_var EASYRSA_REQ_CITY       "San Francisco"
set_var EASYRSA_REQ_ORG        "OpenVPN"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "Community VPN"
set_var EASYRSA_KEY_SIZE       2048
EOVARS

./easyrsa init-pki
./easyrsa --batch build-ca nopass
./easyrsa --batch build-server-full server nopass
./easyrsa gen-dh
openvpn --genkey --secret /etc/openvpn/tc.key

CLIENT_NAME="openvpn-config"
./easyrsa --batch build-client-full "$CLIENT_NAME" nopass

mkdir -p /etc/openvpn/server
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn
cp /etc/openvpn/tc.key /etc/openvpn

cat > /etc/openvpn/server/server.conf << EOF
port $port
proto $protocol
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
auth SHA512
tls-crypt /etc/openvpn/tc.key
cipher AES-256-CBC
topology subnet
server 10.8.0.0 255.255.255.0
push "route $VCN_NET $VCN_MASK"
ifconfig-pool-persist ipp.txt
keepalive 10 120
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

for dns_entry in $dns_server; do
  echo "push \"dhcp-option DNS $dns_entry\"" >> /etc/openvpn/server/server.conf
done

ln -sf /etc/openvpn/server/server.conf /etc/openvpn/server.conf
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p 2>/dev/null || true

if systemctl start openvpn-server@server 2>/dev/null; then
  systemctl enable openvpn-server@server
elif systemctl start openvpn@server 2>/dev/null; then
  systemctl enable openvpn@server
else
  log "WARNING: Could not start OpenVPN service."
fi

PRIMARY_IF=$(ip route show default | awk '/default/ {print $5}' | head -1)
[[ -z "$PRIMARY_IF" ]] && PRIMARY_IF="ens3"

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
iptables -A INPUT -p "$protocol" --dport "$port" -j ACCEPT
iptables -A INPUT -i tun0 -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -i tun0 -d "$VCN_CIDR" -j ACCEPT
iptables -A FORWARD -s "$VCN_CIDR" -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i tun0 -o "$PRIMARY_IF" -j ACCEPT
iptables -A FORWARD -i "$PRIMARY_IF" -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$PRIMARY_IF" -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -d "$VCN_CIDR" -j MASQUERADE
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4
systemctl enable netfilter-persistent 2>/dev/null || true
netfilter-persistent save 2>/dev/null || true

CLIENT_DIR="/etc/openvpn/client-configs"
mkdir -p "$CLIENT_DIR/files"
cat > "$CLIENT_DIR/base.conf" << EOF
client
dev tun
proto $protocol
remote $public_ip $port
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
ignore-unknown-option block-outside-dns
verb 3
EOF

cp "$EASY_RSA_DIR/pki/ca.crt" "$CLIENT_DIR/files/"
cp "$EASY_RSA_DIR/pki/issued/$CLIENT_NAME.crt" "$CLIENT_DIR/files/"
cp "$EASY_RSA_DIR/pki/private/$CLIENT_NAME.key" "$CLIENT_DIR/files/"
cp /etc/openvpn/tc.key "$CLIENT_DIR/files/"

ovpn_file="$CLIENT_DIR/files/$CLIENT_NAME.ovpn"
{
  cat "$CLIENT_DIR/base.conf"
  echo "<ca>"; cat "$CLIENT_DIR/files/ca.crt"; echo "</ca>"
  echo "<cert>"; cat "$CLIENT_DIR/files/$CLIENT_NAME.crt"; echo "</cert>"
  echo "<key>"; cat "$CLIENT_DIR/files/$CLIENT_NAME.key"; echo "</key>"
  echo "<tls-crypt>"; cat "$CLIENT_DIR/files/tc.key"; echo "</tls-crypt>"
} > "$ovpn_file"

# --- Gravar menu em /opt (igual ao modelo dbsystems/wln/psql) ---
install -d /opt
cat > /opt/openvpn-ubuntu-install.sh << 'END_SCRIPT'
#!/bin/bash
if readlink /proc/$$/exe | grep -q "dash"; then
  echo 'This installer needs to be run with "bash", not "sh".'
  exit
fi
read -N 999999 -t 0.001
if systemctl is-active --quiet openvpn-server@server 2>/dev/null || systemctl is-active --quiet openvpn@server 2>/dev/null; then
  echo "OpenVPN is already installed and running."
  echo
  echo "Select an option:"
  echo "   1) Add a new client"
  echo "   2) Revoke an existing client"
  echo "   3) Remove OpenVPN"
  echo "   4) Exit"
  read -p "Choose an option: " option
  case "$option" in
    1)
      read -p "Enter client name (e.g., client1): " CLIENT_NAME
      OVPN_PORT=$(grep -E '^port ' /etc/openvpn/server/server.conf 2>/dev/null | awk '{print $2}')
      OVPN_PORT=$${OVPN_PORT:-1194}
      cd /etc/openvpn/easy-rsa
      ./easyrsa --batch build-client-full "$CLIENT_NAME" nopass
      CLIENT_DIR="/etc/openvpn/client-configs"
      mkdir -p "$CLIENT_DIR/files"
      cp /etc/openvpn/easy-rsa/pki/ca.crt "$CLIENT_DIR/files/"
      cp "/etc/openvpn/easy-rsa/pki/issued/$${CLIENT_NAME}.crt" "$CLIENT_DIR/files/"
      cp "/etc/openvpn/easy-rsa/pki/private/$${CLIENT_NAME}.key" "$CLIENT_DIR/files/"
      cp /etc/openvpn/tc.key "$CLIENT_DIR/files/"
      ovpn_file="$CLIENT_DIR/files/$${CLIENT_NAME}.ovpn"
      cat > "$ovpn_file" <<EOF
client
dev tun
proto udp
remote $(curl -s ifconfig.me) 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
ignore-unknown-option block-outside-dns
verb 3
<ca>
$(cat "$CLIENT_DIR/files/ca.crt")
</ca>
<cert>
$(cat "$CLIENT_DIR/files/$${CLIENT_NAME}.crt")
</cert>
<key>
$(cat "$CLIENT_DIR/files/$${CLIENT_NAME}.key")
</key>
<tls-crypt>
$(cat "$CLIENT_DIR/files/tc.key")
</tls-crypt>
EOF
      echo "Client configuration file created at: $ovpn_file"
      ;;
    2)
      echo "Select a client to revoke:"
      cd /etc/openvpn/easy-rsa
      for cert in pki/issued/*.crt; do
        [[ -f "$cert" ]] || continue
        client_name=$(basename "$cert" .crt)
        [[ "$client_name" == "server" ]] && continue
        echo "$client_name"
      done
      read -p "Enter the client name to revoke: " CLIENT_NAME
      ./easyrsa --batch revoke "$CLIENT_NAME"
      ./easyrsa gen-crl
      mkdir -p /etc/openvpn/server
      cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
      echo "Client $CLIENT_NAME has been revoked."
      ;;
    3)
      echo "Removing OpenVPN..."
      systemctl stop openvpn-server@server 2>/dev/null || true
      systemctl stop openvpn@server 2>/dev/null || true
      systemctl disable openvpn-server@server 2>/dev/null || true
      systemctl disable openvpn@server 2>/dev/null || true
      apt-get remove --purge -y openvpn easy-rsa
      rm -rf /etc/openvpn
      rm -f /opt/openvpn-ubuntu-install.sh
      echo "OpenVPN has been removed."
      ;;
    4) exit 0 ;;
    *) exit 1 ;;
  esac
  exit 0
fi
echo "OpenVPN is not running. Initial install was done by cloud-init."
END_SCRIPT
sed -i "/remote.*ifconfig.me/s/ 1194$/ $port/" /opt/openvpn-ubuntu-install.sh
chmod +x /opt/openvpn-ubuntu-install.sh

touch /var/run/openvpn-install-done
log "OpenVPN install completed. Push route: $VCN_NET $VCN_MASK (split tunnel). Menu: /opt/openvpn-ubuntu-install.sh"
