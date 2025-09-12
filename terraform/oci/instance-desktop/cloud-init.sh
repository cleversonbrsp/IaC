#!/bin/bash
set -e

# ===============================
# Cloud-init script - Ubuntu XFCE + XRDP + Apps
# Author: Cleverson Rodrigues
# ===============================

# --- Variáveis ---
USERNAME="devuser"
PASSWORD="Pass123"  # Troque para senha segura

# --- Atualizar pacotes ---
apt update -y
apt upgrade -y

# --- Instalar XFCE Desktop Environment e LightDM ---
DEBIAN_FRONTEND=noninteractive apt install -y xfce4 xfce4-goodies lightdm

# Definir LightDM como display manager padrão
echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections
systemctl set-default graphical.target
systemctl enable lightdm

# --- Criar usuário para RDP ---
id -u $USERNAME &>/dev/null || useradd -m -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG sudo $USERNAME

# --- Instalar e habilitar XRDP ---
apt install -y xrdp

# Configurar XRDP para usar XFCE
echo "startxfce4" > /etc/skel/.Xclients
chmod +x /etc/skel/.Xclients

echo "startxfce4" > /etc/xrdp/startwm.sh
chmod +x /etc/xrdp/startwm.sh

echo "startxfce4" > /home/$USERNAME/.Xclients
chmod +x /home/$USERNAME/.Xclients
chown $USERNAME:$USERNAME /home/$USERNAME/.Xclients

systemctl enable xrdp
systemctl start xrdp

# --- Instalar aplicativos essenciais ---
apt install -y terminator firefox keepassxc vim remmina dbeaver-ce insomnia

# --- Instalar VSCode ---
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
apt update -y
apt install -y code

# --- Configurar firewall para RDP ---
ufw allow 3389/tcp
ufw --force enable

# --- Finalizar ---
reboot
