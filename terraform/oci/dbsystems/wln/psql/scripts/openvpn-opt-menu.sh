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

            # Port from server config (aligned with Terraform openvpn_port)
            OVPN_PORT=$(grep -E '^port ' /etc/openvpn/server/server.conf 2>/dev/null | awk '{print $2}')
            OVPN_PORT=${OVPN_PORT:-1194}

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
