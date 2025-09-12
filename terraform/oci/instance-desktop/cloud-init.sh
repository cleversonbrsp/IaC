#!/bin/bash
set -e

# ===============================
# Cloud-init script - Ubuntu Minimal → XFCE + XRDP + Apps
# Author: Cleverson Rodrigues
# ===============================

USERNAME="devuser"
PASSWORD="Pass123"  # Troque para senha segura

# --- Atualizar pacotes ---
apt update -y
apt upgrade -y

# --- Dependências para Desktop em Ubuntu Minimal ---
apt install -y \
    xorg dbus-x11 x11-xserver-utils xserver-xorg-video-all \
    fonts-dejavu fonts-liberation \
    gvfs policykit-1 \
    pulseaudio pavucontrol \
    network-manager network-manager-gnome

# --- Remover gdm3 (se presente, para não conflitar com lightdm) ---
apt purge -y gdm3 || true

# --- Definir LightDM como display manager padrão ---
echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections

# --- Instalar XFCE + LightDM + Greeter ---
DEBIAN_FRONTEND=noninteractive apt install -y \
    xfce4 xfce4-goodies lightdm slick-greeter

# Forçar lightdm como padrão
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager

# Garantir boot gráfico
systemctl set-default graphical.target

# --- Criar usuário para RDP ---
id -u $USERNAME &>/dev/null || adduser --disabled-password --gecos "" $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG sudo $USERNAME

# --- Instalar e habilitar XRDP ---
apt install -y xrdp
systemctl enable xrdp
systemctl start xrdp

# --- Garantir compatibilidade do Xorg com XRDP ---
apt install -y xserver-xorg-core xserver-xorg-legacy
systemctl restart xrdp

# --- Configurar XRDP para usar XFCE diretamente ---
cat > /etc/xrdp/startwm.sh << 'EOF'
if test -r /etc/profile; then
        . /etc/profile
fi
startxfce4
EOF

chmod +x /etc/xrdp/startwm.sh

# --- Criar .Xclients do usuário para XFCE ---
echo "startxfce4" > /home/$USERNAME/.Xclients
chmod +x /home/$USERNAME/.Xclients
chown $USERNAME:$USERNAME /home/$USERNAME/.Xclients

# --- Instalar aplicativos essenciais ---
apt install -y terminator firefox keepassxc vim remmina

# --- Instalar DBeaver e Insomnia (via Snap) ---
snap install dbeaver-ce
snap install insomnia

# --- Instalar VSCode ---
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
apt update -y
apt install -y code

# --- Configurar firewall para SSH + RDP ---
ufw allow 22/tcp
ufw allow 3389/tcp
ufw --force enable

# --- Finalizar ---
reboot
