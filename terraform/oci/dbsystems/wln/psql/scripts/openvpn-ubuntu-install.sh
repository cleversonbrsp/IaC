#!/bin/bash
#
# https://github.com/Nyr/openvpn-install
#
# Copyright (c) 2013 Nyr. Released under the MIT License.

# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
        echo 'This installer needs to be run with "bash", not "sh".'
        exit
fi

# Discard stdin. Needed when running from an one-liner which includes a newline
read -N 999999 -t 0.001

# Check if OpenVPN is already installed and running
if systemctl is-active --quiet openvpn@server; then
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
            CLIENT_NAME="openvpn-config"
            echo "Using default client name: $CLIENT_NAME"

            # Port from server config (same as Terraform openvpn_port)
            OVPN_PORT=$(grep -E '^port ' /etc/openvpn/server/server.conf 2>/dev/null | awk '{print $2}')
            OVPN_PORT=$${OVPN_PORT:-1194}

            # Generate client certificate
            cd /etc/openvpn/easy-rsa
            ./easyrsa --batch build-client-full "$CLIENT_NAME" nopass

            # Create client configuration file
            CLIENT_DIR="/etc/openvpn/client-configs"
            mkdir -p "$CLIENT_DIR/files"
            cp /etc/openvpn/easy-rsa/pki/ca.crt "$CLIENT_DIR/files/"
            cp /etc/openvpn/easy-rsa/pki/issued/$CLIENT_NAME.crt "$CLIENT_DIR/files/"
            cp /etc/openvpn/easy-rsa/pki/private/$CLIENT_NAME.key "$CLIENT_DIR/files/"
            cp /etc/openvpn/tc.key "$CLIENT_DIR/files/"

            # Create the .ovpn configuration file
            ovpn_file="$CLIENT_DIR/files/$CLIENT_NAME.ovpn"
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
$(cat "$CLIENT_DIR/files/$CLIENT_NAME.crt")
</cert>
<key>
$(cat "$CLIENT_DIR/files/$CLIENT_NAME.key")
</key>
<tls-crypt>
$(cat "$CLIENT_DIR/files/tc.key")
</tls-crypt>
EOF
            echo "Client configuration file created at: $ovpn_file"
            ;;
        2)
            # Revoke an existing client
            echo "Select a client to revoke:"
            cd /etc/openvpn/easy-rsa
            echo "Listing existing client certificates:"
            for cert in pki/issued/*.crt; do
                client_name=$(basename "$cert" .crt)
                echo "$client_name"
            done
            read -p "Enter the client name to revoke: " CLIENT_NAME
            ./easyrsa --batch revoke "$CLIENT_NAME"
            ./easyrsa gen-crl
            cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
            echo "Client $CLIENT_NAME has been revoked."
            ;;

        3)
            echo "Removing OpenVPN..."
            systemctl stop openvpn@server
            systemctl disable openvpn@server
            apt-get remove --purge -y openvpn easy-rsa
            rm -rf /etc/openvpn
            echo "OpenVPN has been removed."
            ;;
        4)
            echo "Exiting..."
            exit
            ;;
        *)
            echo "Invalid option. Exiting..."
            exit
            ;;
    esac
    exit
fi

# If OpenVPN is not installed, proceed with the installation

LOG="/var/log/openvpn-install.log"
log() { echo "$(date -Iseconds) $*" >> "$LOG"; }

# Check for root privileges
if [[ "$EUID" -ne 0 ]]; then
        echo "This script must be run as root."
        exit
fi

# Detect OS and version
if [[ -e /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=$VERSION_ID
else
        echo "Cannot detect the operating system. Unsupported version."
        exit
fi

if [[ $OS == "ubuntu" && ( $VERSION_ID == "20.04" || $VERSION_ID == "22.04" || $VERSION_ID == "24.04" ) ]]; then
        echo "Supported Ubuntu version detected: $VERSION_ID"
else
        echo "Unsupported version: $OS $VERSION_ID. This script supports Ubuntu 20.04, 22.04 and 24.04."
        exit
fi

# Install necessary packages (retry once on failure for transient network)
log "Starting OpenVPN install"
apt-get update -qq || { sleep 10; apt-get update -qq; }
apt-get install -y openvpn easy-rsa wget curl iptables-persistent || { log "apt install failed, retrying"; sleep 15; apt-get install -y openvpn easy-rsa wget curl iptables-persistent; }
log "Packages installed"

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/^#net.ipv4.ip_forward=1/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
sysctl -p

# Defaults (non-interactive for cloud-init). Port from Terraform var.openvpn_port.
echo "Detecting public IP..."
public_ip=$(curl -s ifconfig.me)
echo "Using public IP: $public_ip"
port="${openvpn_port}"
[ -z "$port" ] || [ "$port" = "0" ] && port=1194
protocol="udp"
echo "Using port: $port (from Terraform openvpn_port)"
echo "Using default protocol: $protocol"

# DNS (same as prod)
dns_server="10.10.1.190"
echo "Using default DNS: $dns_server"
case "$dns" in
    1)
        if grep -q '^nameserver 127.0.0.53' "/etc/resolv.conf"; then
            resolv_conf="/run/systemd/resolve/resolv.conf"
        else
            resolv_conf="/etc/resolv.conf"
        fi
        dns_server="$(grep -v '^#\|^;' "$resolv_conf" | grep '^nameserver' | awk '{print $2}' | tr '\n' ' ')";;
    2)
        dns_server="10.10.1.190";;
    3)
        dns_server="1.1.1.1 1.0.0.1";;
    4)
        dns_server="208.67.222.222 208.67.220.220";;
    5)
        dns_server="9.9.9.9 149.112.112.112";;
    6)
        dns_server="94.140.14.14 94.140.15.15";;
    *)
        dns_server="10.10.1.190";;
esac

# Push route for DB subnet (templatefile: db_subnet_cidr)
DB_SUBNET="${db_subnet_cidr}"
DB_NET=$(echo "$DB_SUBNET" | cut -d/ -f1)
DB_MASK_BITS=$(echo "$DB_SUBNET" | cut -d/ -f2)
case "$DB_MASK_BITS" in
  24) DB_MASK="255.255.255.0";;
  16) DB_MASK="255.255.0.0";;
  8)  DB_MASK="255.0.0.0";;
  *)  DB_MASK="255.255.255.0";;
esac

# Easy-RSA (same as prod)
EASY_RSA_DIR=/etc/openvpn/easy-rsa
if [[ ! -d "$EASY_RSA_DIR" ]]; then
        mkdir -p $EASY_RSA_DIR
        ln -s /usr/share/easy-rsa/* $EASY_RSA_DIR/
fi

cd $EASY_RSA_DIR
cp vars vars.bak 2>/dev/null || true

cat > vars << EOF
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "California"
set_var EASYRSA_REQ_CITY       "San Francisco"
set_var EASYRSA_REQ_ORG        "OpenVPN"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "Community VPN"
set_var EASYRSA_KEY_SIZE       2048
EOF

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

# Server configuration (prod + push route for DB)
cat > /etc/openvpn/server/server.conf << EOF
port $port
proto $protocol
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-crypt /etc/openvpn/tc.key
cipher AES-256-CBC
topology subnet
server 10.8.0.0 255.255.255.0
push "route $DB_NET $DB_MASK"
EOF

ip6=$(ip -6 route show default 2>/dev/null | grep -c "" || true)
if [[ -z "$ip6" || "$ip6" -eq 0 ]]; then
        echo 'push "redirect-gateway def1 bypass-dhcp"' >> /etc/openvpn/server/server.conf
else
        echo 'server-ipv6 fddd:1194:1194:1194::/64' >> /etc/openvpn/server/server.conf
        echo 'push "redirect-gateway def1 ipv6 bypass-dhcp"' >> /etc/openvpn/server/server.conf
fi

echo 'ifconfig-pool-persist ipp.txt' >> /etc/openvpn/server/server.conf
for dns_entry in $dns_server; do
        echo "push \"dhcp-option DNS $dns_entry\"" >> /etc/openvpn/server/server.conf
done
echo "keepalive 10 120" >> /etc/openvpn/server/server.conf
echo "persist-key" >> /etc/openvpn/server/server.conf
echo "persist-tun" >> /etc/openvpn/server/server.conf
echo "status openvpn-status.log" >> /etc/openvpn/server/server.conf
echo "verb 3" >> /etc/openvpn/server/server.conf

ln -sf /etc/openvpn/server/server.conf /etc/openvpn/server.conf
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p 2>/dev/null || true

systemctl start openvpn@server
systemctl enable openvpn@server

# iptables (prod: ens3; OCI may use different interface)
PRIMARY_IF=$(ip route show default | awk '/default/ {print $5}' | head -1)
[[ -z "$PRIMARY_IF" ]] && PRIMARY_IF="ens3"
echo "Configuring iptables rules (interface: $PRIMARY_IF)..."

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

iptables -A INPUT -p $protocol --dport $port -j ACCEPT
iptables -A FORWARD -i tun0 -o $PRIMARY_IF -j ACCEPT
iptables -A FORWARD -i $PRIMARY_IF -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $PRIMARY_IF -j MASQUERADE

iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4
systemctl enable netfilter-persistent 2>/dev/null || true
netfilter-persistent save 2>/dev/null || true

# Client config (same as prod)
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
    echo "<ca>"
    cat "$CLIENT_DIR/files/ca.crt"
    echo "</ca>"
    echo "<cert>"
    cat "$CLIENT_DIR/files/$CLIENT_NAME.crt"
    echo "</cert>"
    echo "<key>"
    cat "$CLIENT_DIR/files/$CLIENT_NAME.key"
    echo "</key>"
    echo "<tls-crypt>"
    cat "$CLIENT_DIR/files/tc.key"
    echo "</tls-crypt>"
} > "$ovpn_file"

echo "Client configuration file created at: $ovpn_file"
echo "Use this file to connect to your OpenVPN server."
echo "OpenVPN installation completed. Your server is now running."
echo "Public IP used: $public_ip, Port: $port, Protocol: $protocol."
echo "Client configuration for '$CLIENT_NAME' is ready at $ovpn_file."
echo "Push route for DB subnet: $DB_NET $DB_MASK"

# Save menu script to /opt for later (add client, revoke, etc.) - igual ao prod
cat > /opt/openvpn-ubuntu-install.sh << 'END_SCRIPT'
#!/bin/bash
#
# https://github.com/Nyr/openvpn-install
#
# Copyright (c) 2013 Nyr. Released under the MIT License.

# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
        echo 'This installer needs to be run with "bash", not "sh".'
        exit
fi

# Discard stdin. Needed when running from an one-liner which includes a newline
read -N 999999 -t 0.001

# Check if OpenVPN is already installed and running
if systemctl is-active --quiet openvpn@server; then
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
            # Add a new client
            read -p "Enter client name (e.g., client1): " CLIENT_NAME
            cd /etc/openvpn/easy-rsa
            ./easyrsa --batch build-client-full "$CLIENT_NAME" nopass
            CLIENT_DIR="/etc/openvpn/client-configs"
            mkdir -p "$CLIENT_DIR/files"
            cp /etc/openvpn/easy-rsa/pki/ca.crt "$CLIENT_DIR/files/"
            cp /etc/openvpn/easy-rsa/pki/issued/$CLIENT_NAME.crt "$CLIENT_DIR/files/"
            cp /etc/openvpn/easy-rsa/pki/private/$CLIENT_NAME.key "$CLIENT_DIR/files/"
            cp /etc/openvpn/tc.key "$CLIENT_DIR/files/"

            ovpn_file="$CLIENT_DIR/files/$CLIENT_NAME.ovpn"
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
$(cat "$CLIENT_DIR/files/$CLIENT_NAME.crt")
</cert>
<key>
$(cat "$CLIENT_DIR/files/$CLIENT_NAME.key")
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
                client_name=$(basename "$cert" .crt)
                echo "$client_name"
            done
            read -p "Enter the client name to revoke: " CLIENT_NAME
            ./easyrsa --batch revoke "$CLIENT_NAME"
            ./easyrsa gen-crl
            cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
            echo "Client $CLIENT_NAME has been revoked."
            ;;

        3)
            echo "Removing OpenVPN..."
            systemctl stop openvpn@server
            systemctl disable openvpn@server
            apt-get remove --purge -y openvpn easy-rsa
            rm -rf /etc/openvpn
            echo "OpenVPN has been removed."
            ;;
        4)
            echo "Exiting..."
            exit
            ;;
        *)
            echo "Invalid option. Exiting..."
            exit
            ;;
    esac
    exit
fi

echo "OpenVPN is not running. Initial install was done by cloud-init."
END_SCRIPT
# Inject Terraform openvpn_port into the saved menu script (remote line)
sed -i "/remote.*ifconfig.me/s/ 1194$/ $port/" /opt/openvpn-ubuntu-install.sh
chmod +x /opt/openvpn-ubuntu-install.sh

# Marcador para Terraform/cloud-init: script concluído com sucesso
touch /var/run/openvpn-install-done
log "OpenVPN install completed successfully"
