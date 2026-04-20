#!/bin/bash
set -eo pipefail

# ===============================
# Primeiro boot (user_data) — Ubuntu → XFCE + XRDP
# Enviado como script único em compute_desktop.tf (base64). No início paramos unattended-upgrades
# e esperamos o apt — evita lock sem depender de MIME multipart (na OCI o handler da parte shell
# multipart pode falhar e o cloud-init “done” sem instalar nada).
#
# Objetivo: SO com XFCE acessível por RDP (3389/tcp) para quem estiver na VPN / pool OpenVPN
# (regras de rede em network.tf — NSG + Security List).
# ===============================

export DEBIAN_FRONTEND=noninteractive

USERNAME="devuser"
PASSWORD="Pass123"  # Troque para senha segura

log() { echo "[cloud-init-desktop] $*"; }

stop_apt_competitors() {
  log "Parando unattended-upgrades e timers apt-daily (primeiro boot)..."
  systemctl stop unattended-upgrades.service 2>/dev/null || true
  systemctl stop apt-daily.service apt-daily-upgrade.service 2>/dev/null || true
  systemctl stop apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
  sleep 3
}

wait_for_apt_idle() {
  local w=0 max=360 last_log=0
  log "Verificando locks do apt..."
  while [ "$w" -lt "$max" ]; do
    local busy=0
    pgrep -x apt >/dev/null 2>&1 && busy=1
    pgrep -x apt-get >/dev/null 2>&1 && busy=1
    pgrep -x dpkg >/dev/null 2>&1 && busy=1
    pgrep -f unattended-upgrade >/dev/null 2>&1 && busy=1
    if command -v fuser >/dev/null 2>&1; then
      fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 && busy=1
      fuser /var/lib/dpkg/lock >/dev/null 2>&1 && busy=1
      fuser /var/lib/apt/lists/lock >/dev/null 2>&1 && busy=1
    fi
    if [ "$busy" -eq 0 ]; then
      log "apt livre após ${w}s"
      sleep 2
      return 0
    fi
    if [ "$((w - last_log))" -ge 20 ] || [ "$w" -eq 0 ]; then
      log "ainda ocupado após ${w}s — processos:"
      ps -eo pid,cmd 2>/dev/null | grep -E '[a]pt-get|[a]pt |/[u]nattended|[d]pkg' | head -12 || true
      last_log=$w
    fi
    sleep 3
    w=$((w + 3))
  done
  log "ERRO: timeout (${max}s) aguardando apt"
  return 1
}

configure_xrdp_xfce_session() {
  # startwm.sh: inicia XFCE na sessão xrdp (Xorg/xorgxrdp)
  cat > /etc/xrdp/startwm.sh << 'EOF'
#!/bin/sh
if test -r /etc/profile; then
  . /etc/profile
fi
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
exec startxfce4
EOF
  chmod +x /etc/xrdp/startwm.sh

  # Sessão gráfica para o usuário RDP (alguns caminhos do xrdp leem .xsession / .Xclients)
  echo "xfce4-session" > "/home/$USERNAME/.xsession"
  chmod +x "/home/$USERNAME/.xsession"
  chown "$USERNAME:$USERNAME" "/home/$USERNAME/.xsession"

  echo "startxfce4" > "/home/$USERNAME/.Xclients"
  chmod +x "/home/$USERNAME/.Xclients"
  chown "$USERNAME:$USERNAME" "/home/$USERNAME/.Xclients"

  install -d -m 700 -o "$USERNAME" -g "$USERNAME" "/home/$USERNAME/.config" 2>/dev/null || true
}

# Polkit (colord): evita tela cinza / bloqueios em sessão X remota (Ubuntu 20.04+ com .pkla)
configure_polkit_colord() {
  local pkla_dir="/etc/polkit-1/localauthority/50-local.d"
  if [ -d "$pkla_dir" ]; then
    cat > "$pkla_dir/45-allow-colord.pkla" << 'EOF'
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
  fi
  # Ubuntu 22.04+ (polkit em rules.d)
  if [ -d /etc/polkit-1/rules.d ]; then
    cat > /etc/polkit-1/rules.d/46-xrdp-colord.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.color-manager") == 0) {
        return polkit.Result.YES;
    }
});
EOF
  fi
}

verify_rdp_ready() {
  log "Verificação pós-instalação..."
  if systemctl is-active --quiet xrdp 2>/dev/null && systemctl is-active --quiet xrdp-sesman 2>/dev/null; then
    log "Serviços: xrdp e xrdp-sesman ativos."
  else
    log "AVISO: xrdp ou xrdp-sesman não está ativo — veja journalctl -u xrdp -u xrdp-sesman"
  fi
  if ss -tlnp 2>/dev/null | grep -q ':3389'; then
    log "Porta 3389/tcp em escuta (RDP)."
  else
    log "AVISO: porta 3389 não encontrada em ss — confira configuração do xrdp"
  fi
}

stop_apt_competitors
wait_for_apt_idle

apt-get update -y
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# dbus-user-session: sessão XFCE via xrdp costuma precisar (integração dbus / systemd --user)
apt-get install -y \
    xorg dbus-x11 dbus-user-session x11-xserver-utils xserver-xorg-video-all \
    fonts-dejavu fonts-liberation \
    gvfs policykit-1 \
    pulseaudio pavucontrol \
    network-manager network-manager-gnome

apt-get purge -y gdm3 || true

echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections

apt-get install -y \
    xfce4 xfce4-goodies xfce4-session lightdm slick-greeter

echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
systemctl set-default graphical.target

id -u "$USERNAME" &>/dev/null || adduser --disabled-password --gecos "" "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG sudo "$USERNAME"

apt-get install -y xrdp xorgxrdp xserver-xorg-core xserver-xorg-legacy

getent group ssl-cert >/dev/null && usermod -a -G ssl-cert xrdp 2>/dev/null || true

configure_polkit_colord
configure_xrdp_xfce_session

# Habilitar e subir xrdp + sesman (ambos necessários para login RDP)
systemctl enable xrdp xrdp-sesman
systemctl restart xrdp-sesman xrdp

apt-get install -y terminator firefox keepassxc vim remmina || log "Aviso: algum pacote opcional falhou"

ufw allow 22/tcp
ufw allow 3389/tcp
ufw --force enable

systemctl start apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true

verify_rdp_ready
log "XFCE + xrdp configurados. Acesso RDP na VPN: usuário $USERNAME (porta 3389/tcp)."
touch /opt/.instance-desktop-rdp-ready
