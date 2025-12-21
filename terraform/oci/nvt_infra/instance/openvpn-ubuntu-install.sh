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
            # Revoke an existing client
            echo "Select a client to revoke:"
            # List all client certificates
            cd /etc/openvpn/easy-rsa
            echo "Listing existing client certificates:"
            for cert in pki/issued/*.crt; do
                # Extract client name from the certificate file name
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
            # Remove OpenVPN
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

# If OpenVPN is not installed, proceed with the installation as per the original script

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

if [[ $OS == "ubuntu" && ( $VERSION_ID == "20.04" || $VERSION_ID == "22.04" ) ]]; then
        echo "Supported Ubuntu version detected: $VERSION_ID"
else
        echo "Unsupported version: $OS $VERSION_ID. This script supports Ubuntu 20.04 and 22.04."
        exit
fi

# Install necessary packages
apt-get update
apt-get install -y openvpn easy-rsa wget curl iptables-persistent

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/^#net.ipv4.ip_forward=1/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
sysctl -p

# Use default public IP
echo "Detecting public IP..."
public_ip=$(curl -s ifconfig.me)
echo "Using public IP: $public_ip"

# Use default port and protocol
port=1194
protocol="udp"
echo "Using default port: $port"
echo "Using default protocol: $protocol"

# Use Google DNS by default
dns_server="10.10.1.190"
echo "Using default DNS: Google ($dns_server)"

case "$dns" in
    1)
        # Locate the proper resolv.conf
        if grep -q '^nameserver 127.0.0.53' "/etc/resolv.conf"; then
            resolv_conf="/run/systemd/resolve/resolv.conf"
        else
            resolv_conf="/etc/resolv.conf"
        fi
        # Obtain the resolvers from resolv.conf
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

# Make sure Easy-RSA is available
EASY_RSA_DIR=/etc/openvpn/easy-rsa
if [[ ! -d "$EASY_RSA_DIR" ]]; then
        mkdir -p $EASY_RSA_DIR
        ln -s /usr/share/easy-rsa/* $EASY_RSA_DIR/
fi

# Set up Easy-RSA
cd $EASY_RSA_DIR
cp vars vars.bak  # Backup default vars

# Customize vars
cat > vars << EOF
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "California"
set_var EASYRSA_REQ_CITY       "San Francisco"
set_var EASYRSA_REQ_ORG        "OpenVPN"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "Community VPN"
set_var EASYRSA_KEY_SIZE       2048
EOF

# Initialize PKI
./easyrsa init-pki

# Build CA (non-interactive)
./easyrsa --batch build-ca nopass

# Generate Server Certificate and Key
./easyrsa --batch build-server-full server nopass

# Generate Diffie-Hellman parameters
./easyrsa gen-dh

# Generate TLS-crypt key
openvpn --genkey --secret /etc/openvpn/tc.key

# Prompt for client name
read -p "Enter client name (e.g., client1): " CLIENT_NAME

# Generate client certificate (example client)
./easyrsa --batch build-client-full "$CLIENT_NAME" nopass

# Ensure /etc/openvpn/server directory exists
mkdir -p /etc/openvpn/server

# Copy configuration files
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn
cp /etc/openvpn/tc.key /etc/openvpn

# Generate server configuration
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
EOF

# IPv6 support
ip6=$(ip -6 route show default | grep -c "")
if [[ -z "$ip6" ]]; then
        echo 'push "redirect-gateway def1 bypass-dhcp"' >> /etc/openvpn/server/server.conf
else
        echo 'server-ipv6 fddd:1194:1194:1194::/64' >> /etc/openvpn/server/server.conf
        echo 'push "redirect-gateway def1 ipv6 bypass-dhcp"' >> /etc/openvpn/server/server.conf
fi

echo 'ifconfig-pool-persist ipp.txt' >> /etc/openvpn/server/server.conf

# DNS setup
for dns_entry in $dns_server; do
        echo "push \"dhcp-option DNS $dns_entry\"" >> /etc/openvpn/server/server.conf
done

echo "keepalive 10 120" >> /etc/openvpn/server/server.conf
echo "persist-key" >> /etc/openvpn/server/server.conf
echo "persist-tun" >> /etc/openvpn/server/server.conf
echo "status openvpn-status.log" >> /etc/openvpn/server/server.conf
echo "verb 3" >> /etc/openvpn/server/server.conf

# Ensure OpenVPN recognizes the correct path
ln -sf /etc/openvpn/server/server.conf /etc/openvpn/server.conf

# Enable IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Start and enable OpenVPN server
systemctl start openvpn@server
systemctl enable openvpn@server

# Configure iptables
echo "Configuring iptables rules..."

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
iptables -A FORWARD -i tun0 -o ens3 -j ACCEPT
iptables -A FORWARD -i ens3 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ens3 -j MASQUERADE

iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

# Save iptables rules
iptables-save > /etc/iptables/rules.v4
systemctl enable netfilter-persistent
netfilter-persistent save

# Create client configuration directory
CLIENT_DIR="/etc/openvpn/client-configs"
mkdir -p "$CLIENT_DIR/files"

# Client template
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

# Generate client .ovpn file
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

# Final message with path
echo "Client configuration file created at: $ovpn_file"
echo "Use this file to connect to your OpenVPN server."
echo "OpenVPN installation completed. Your server is now running."
echo "Public IP used: $public_ip, Port: $port, Protocol: $protocol."
echo "Client configuration for '$CLIENT_NAME' is ready at $ovpn_file."
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
            # Generate client certificate (example client)
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
            # Revoke an existing client
            echo "Select a client to revoke:"
            # List all client certificates
            cd /etc/openvpn/easy-rsa
            echo "Listing existing client certificates:"
            for cert in pki/issued/*.crt; do
                # Extract client name from the certificate file name
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
            # Remove OpenVPN
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

# If OpenVPN is not installed, proceed with the installation as per the original script

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

if [[ $OS == "ubuntu" && ( $VERSION_ID == "20.04" || $VERSION_ID == "22.04" ) ]]; then
        echo "Supported Ubuntu version detected: $VERSION_ID"
else
        echo "Unsupported version: $OS $VERSION_ID. This script supports Ubuntu 20.04 and 22.04."
        exit
fi

# Install necessary packages
apt-get update
apt-get install -y openvpn easy-rsa wget curl iptables-persistent

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/^#net.ipv4.ip_forward=1/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
sysctl -p

# Prompt for public IP
public_ip=$(curl -s ifconfig.me)
read -p "Detected public IP is $public_ip. Press Enter to use this or input a custom IP: " custom_ip
if [[ -n "$custom_ip" ]]; then
    public_ip=$custom_ip
fi

# Prompt for port and protocol
read -p "Enter port number for OpenVPN [1194]: " port
port=${port:-1194}

read -p "Enter protocol (udp/tcp) [udp]: " protocol
protocol=${protocol:-udp}

# Select DNS server
echo
echo "Select a DNS server for the clients:"
echo "   1) Current system resolvers"
echo "   2) Google"
echo "   3) 1.1.1.1"
echo "   4) OpenDNS"
echo "   5) Quad9"
echo "   6) AdGuard"
read -p "DNS server [1]: " dns
until [[ -z "$dns" || "$dns" =~ ^[1-6]$ ]]; do
    echo "$dns: invalid selection."
    read -p "DNS server [1]: " dns
done

case "$dns" in
    1)
        # Locate the proper resolv.conf
        if grep -q '^nameserver 127.0.0.53' "/etc/resolv.conf"; then
            resolv_conf="/run/systemd/resolve/resolv.conf"
        else
            resolv_conf="/etc/resolv.conf"
        fi
        # Obtain the resolvers from resolv.conf
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

# Make sure Easy-RSA is available
EASY_RSA_DIR=/etc/openvpn/easy-rsa
if [[ ! -d "$EASY_RSA_DIR" ]]; then
        mkdir -p $EASY_RSA_DIR
        ln -s /usr/share/easy-rsa/* $EASY_RSA_DIR/
fi

# Set up Easy-RSA
cd $EASY_RSA_DIR
cp vars vars.bak  # Backup default vars

# Customize vars
cat > vars << EOF
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "California"
set_var EASYRSA_REQ_CITY       "San Francisco"
set_var EASYRSA_REQ_ORG        "OpenVPN"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "Community VPN"
set_var EASYRSA_KEY_SIZE       2048
EOF

# Initialize PKI
./easyrsa init-pki

# Build CA (non-interactive)
./easyrsa --batch build-ca nopass

# Generate Server Certificate and Key
./easyrsa --batch build-server-full server nopass

# Generate Diffie-Hellman parameters
./easyrsa gen-dh

# Generate TLS-crypt key
openvpn --genkey --secret /etc/openvpn/tc.key

# Prompt for client name
read -p "Enter client name (e.g., client1): " CLIENT_NAME

# Generate client certificate (example client)
./easyrsa --batch build-client-full "$CLIENT_NAME" nopass

# Ensure /etc/openvpn/server directory exists
mkdir -p /etc/openvpn/server

# Copy configuration files
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn
cp /etc/openvpn/tc.key /etc/openvpn

# Generate server configuration
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
EOF

# IPv6 support
ip6=$(ip -6 route show default | grep -c "")
if [[ -z "$ip6" ]]; then
        echo 'push "redirect-gateway def1 bypass-dhcp"' >> /etc/openvpn/server/server.conf
else
        echo 'server-ipv6 fddd:1194:1194:1194::/64' >> /etc/openvpn/server/server.conf
        echo 'push "redirect-gateway def1 ipv6 bypass-dhcp"' >> /etc/openvpn/server/server.conf
fi

echo 'ifconfig-pool-persist ipp.txt' >> /etc/openvpn/server/server.conf

# DNS setup
for dns_entry in $dns_server; do
        echo "push \"dhcp-option DNS $dns_entry\"" >> /etc/openvpn/server/server.conf
done

echo "keepalive 10 120" >> /etc/openvpn/server/server.conf
echo "persist-key" >> /etc/openvpn/server/server.conf
echo "persist-tun" >> /etc/openvpn/server/server.conf
echo "status openvpn-status.log" >> /etc/openvpn/server/server.conf
echo "verb 3" >> /etc/openvpn/server/server.conf

# Ensure OpenVPN recognizes the correct path
ln -sf /etc/openvpn/server/server.conf /etc/openvpn/server.conf

# Enable IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Start and enable OpenVPN server
systemctl start openvpn@server
systemctl enable openvpn@server

# Configure iptables
echo "Configuring iptables rules..."

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
iptables -A FORWARD -i tun0 -o ens3 -j ACCEPT
iptables -A FORWARD -i ens3 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ens3 -j MASQUERADE

iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

# Save iptables rules
iptables-save > /etc/iptables/rules.v4
systemctl enable netfilter-persistent
netfilter-persistent save

# Create client configuration directory
CLIENT_DIR="/etc/openvpn/client-configs"
mkdir -p "$CLIENT_DIR/files"

# Client template
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

# Generate client .ovpn file
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

# Final message with path
echo "Client configuration file created at: $ovpn_file"
echo "Use this file to connect to your OpenVPN server."
echo "OpenVPN installation completed. Your server is now running."
echo "Public IP used: $public_ip, Port: $port, Protocol: $protocol."
echo "Client configuration for '$CLIENT_NAME' is ready at $ovpn_file."
END_SCRIPT
chmod u+x /opt/openvpn-ubuntu-install.sh