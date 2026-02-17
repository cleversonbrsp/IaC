#!/bin/bash
set -euxo pipefail

# Log de inicialização
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "=== Iniciando configuração do servidor DayZ ==="
date

# 1. Atualização do sistema
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install -y \
  software-properties-common \
  curl \
  wget \
  unzip \
  net-tools \
  lib32gcc-s1 \
  lib32stdc++6 \
  ca-certificates \
  sudo \
  screen \
  htop \
  ufw \
  iptables \
  fail2ban \
  git

# 2. Criação do usuário dayz
if ! id -u dayz >/dev/null 2>&1; then
  useradd -m -s /bin/bash dayz
  echo "dayz:DayZ@Server2025!" | chpasswd
  usermod -aG sudo dayz
  echo "dayz ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/dayz
fi

# 3. Configuração de firewall (portas DayZ)
# ⚠️ TEMPORÁRIO: Permitir TODO o tráfego para testes (remover em produção)
ufw --force enable
ufw default allow incoming  # ⚠️ TEMPORÁRIO - mudar para 'deny' em produção
ufw default allow outgoing
# Regras específicas (mantidas para referência, mas não necessárias com allow all)
ufw allow 22/tcp
ufw allow 2302/tcp
ufw allow 2302/udp
ufw allow 2303:2305/udp
ufw allow 2306/udp
ufw allow 27016/udp

# 4. Instalação do SteamCMD
mkdir -p /opt/steamcmd
cd /opt/steamcmd
if [ ! -f steamcmd.sh ]; then
  wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
  tar -xzf steamcmd_linux.tar.gz
  rm steamcmd_linux.tar.gz
fi
chown -R dayz:dayz /opt/steamcmd

# 5. Diretórios do servidor DayZ
mkdir -p /home/dayz/dayzserver
mkdir -p /home/dayz/dayzserver/profile
mkdir -p /home/dayz/dayzserver/logs
chown -R dayz:dayz /home/dayz

# 6. Instalação AUTOMÁTICA do servidor DayZ (baseado em https://community.bistudio.com/wiki/DayZ:Hosting_a_Linux_Server)
echo "=== Instalando servidor DayZ via SteamCMD ==="

# Determinar método de login (anônimo ou com conta Steam)
# Variáveis do Terraform são passadas diretamente
STEAM_USER="${steam_username}"
STEAM_PASS="${steam_password}"

# Se steam_username estiver vazio, usar anonymous
if [ -z "$STEAM_USER" ]; then
  STEAM_USER="anonymous"
fi

if [ "$STEAM_USER" = "anonymous" ]; then
  echo "Usando login anônimo (pode ter limitações)"
  LOGIN_CMD="+login anonymous"
elif [ -n "$STEAM_PASS" ]; then
  echo "⚠️ ATENÇÃO: Usando senha do Steam via variável (NÃO RECOMENDADO por segurança)"
  echo "   A senha será armazenada em texto plano no user-data!"
  echo "Usando login com conta Steam: $STEAM_USER (senha fornecida)"
  LOGIN_CMD="+login $STEAM_USER $STEAM_PASS"
else
  echo "Usando login com conta Steam: $STEAM_USER"
  echo "⚠️ IMPORTANTE: Senha não fornecida - você precisará autenticar manualmente!"
  echo "   O script tentará fazer login, mas vai pedir senha e Steam Guard interativamente."
  echo "   Como o user-data não é interativo, a instalação automática pode falhar."
  echo "   Após o deploy, execute manualmente:"
  echo "   ssh -i ~/.ssh/instance-oci.key ubuntu@<IP_PUBLICO>"
  echo "   sudo su - dayz"
  echo "   cd /opt/steamcmd"
  echo "   ./steamcmd.sh +login $STEAM_USER +force_install_dir /home/dayz/dayzserver +app_update 223350 validate +quit"
  LOGIN_CMD="+login $STEAM_USER"
fi

cd /opt/steamcmd
sudo -u dayz ./steamcmd.sh +force_install_dir /home/dayz/dayzserver \
  $LOGIN_CMD \
  +app_update 223350 validate \
  +quit

# Criar link simbólico se necessário (algumas versões usam DayZServer sem _x64)
if [ -f /home/dayz/dayzserver/DayZServer ] && [ ! -f /home/dayz/dayzserver/DayZServer_x64 ]; then
  ln -s /home/dayz/dayzserver/DayZServer /home/dayz/dayzserver/DayZServer_x64
fi

# Garantir permissões corretas
chown -R dayz:dayz /home/dayz/dayzserver
chmod +x /home/dayz/dayzserver/DayZServer_x64 2>/dev/null || true
chmod +x /home/dayz/dayzserver/DayZServer 2>/dev/null || true

# Script para atualizar o servidor DayZ (para uso futuro)
# Usa o mesmo método de login configurado na instalação inicial
# STEAM_USER e STEAM_PASS já foram definidos acima
if [ -n "$STEAM_PASS" ] && [ "$STEAM_USER" != "anonymous" ]; then
  UPDATE_LOGIN="+login $STEAM_USER $STEAM_PASS"
else
  UPDATE_LOGIN="+login $STEAM_USER"
fi
cat << 'UPDATEEOF' > /home/dayz/update_dayz.sh
#!/bin/bash
set -euxo pipefail
cd /opt/steamcmd
./steamcmd.sh +force_install_dir /home/dayz/dayzserver \
  +login $${1:-anonymous} $${2:-} \
  +app_update 223350 validate \
  +quit

# Garantir permissões corretas
chown -R dayz:dayz /home/dayz/dayzserver
chmod +x /home/dayz/dayzserver/DayZServer_x64 2>/dev/null || true
chmod +x /home/dayz/dayzserver/DayZServer 2>/dev/null || true
echo "Servidor DayZ atualizado com sucesso!"
UPDATEEOF

# Adicionar wrapper que passa as credenciais
cat << 'WRAPPEREOF' > /home/dayz/update_dayz_wrapper.sh
#!/bin/bash
/home/dayz/update_dayz.sh "$STEAM_USER" "$STEAM_PASS"
WRAPPEREOF
chmod +x /home/dayz/update_dayz_wrapper.sh
chown dayz:dayz /home/dayz/update_dayz_wrapper.sh

# Garantir permissões corretas
chown -R dayz:dayz /home/dayz/dayzserver
chmod +x /home/dayz/dayzserver/DayZServer_x64 2>/dev/null || true
chmod +x /home/dayz/dayzserver/DayZServer 2>/dev/null || true
echo "Servidor DayZ atualizado com sucesso!"
EOF

chmod +x /home/dayz/update_dayz.sh
chown dayz:dayz /home/dayz/update_dayz.sh

# 7. Script de inicialização do servidor DayZ (baseado em https://community.bistudio.com/wiki/DayZ:Hosting_a_Linux_Server)
cat << 'EOF' > /home/dayz/start_dayz.sh
#!/bin/bash
set -euxo pipefail
cd /home/dayz/dayzserver

# Criar diretórios necessários
mkdir -p logs
mkdir -p profile
mkdir -p profile/users

# Determinar executável (pode ser DayZServer ou DayZServer_x64)
EXECUTABLE=""
if [ -f "./DayZServer_x64" ]; then
  EXECUTABLE="./DayZServer_x64"
elif [ -f "./DayZServer" ]; then
  EXECUTABLE="./DayZServer"
else
  echo "ERRO: Executável DayZServer não encontrado!"
  exit 1
fi

# Iniciar servidor DayZ com parâmetros recomendados
$EXECUTABLE \
  -config=/home/dayz/dayzserver/serverDZ.cfg \
  -port=2302 \
  -profiles=profile \
  -freezecheck \
  -cpuCount=2 \
  -dologs \
  -adminlog \
  -netlog \
  -scrAllowFileWrite \
  -mission=dayz.chernarusplus \
  -do
EOF

chmod +x /home/dayz/start_dayz.sh
chown dayz:dayz /home/dayz/start_dayz.sh

# 8. Script para iniciar em screen
cat << 'EOF' > /home/dayz/start_dayz_screen.sh
#!/bin/bash
screen -dmS dayz-server bash -c '/home/dayz/start_dayz.sh'
echo "Servidor DayZ iniciado em screen. Use 'screen -r dayz-server' para acessar."
EOF

chmod +x /home/dayz/start_dayz_screen.sh
chown dayz:dayz /home/dayz/start_dayz_screen.sh

# 9. Configuração básica do servidor DayZ (baseado em https://community.bistudio.com/wiki/DayZ:Hosting_a_Linux_Server)
cat << 'EOF' > /home/dayz/dayzserver/serverDZ.cfg
hostname = "DayZ Server OCI";
password = "";
passwordAdmin = "ChangeThisPassword123!";
maxPlayers = 20;  // Ajustado para 2 OCPUs (10-20 jogadores recomendado)
verifySignatures = 2;
verifyMods = 0;  // 0 = não verificar mods (vanilla)
disableVoN = 0;
vonCodecQuality = 7;
disable3rdPerson = 0;
disableCrosshair = 0;
serverTimeAcceleration = 1;
serverNightTimeAcceleration = 1;
serverTimePersistent = 1;
instanceId = 1;  // ⚠️ OBRIGATÓRIO: Deve ser um inteiro de 32 bits válido
EOF

chown dayz:dayz /home/dayz/dayzserver/serverDZ.cfg

# 10. Criar systemd service para o servidor DayZ (inicia automaticamente após instalação)
cat << 'EOF' > /etc/systemd/system/dayz-server.service
[Unit]
Description=DayZ Server
After=network.target

[Service]
Type=simple
User=dayz
WorkingDirectory=/home/dayz/dayzserver
# Determinar executável dinamicamente
ExecStartPre=/bin/bash -c 'if [ -f /home/dayz/dayzserver/DayZServer_x64 ]; then EXEC="/home/dayz/dayzserver/DayZServer_x64"; elif [ -f /home/dayz/dayzserver/DayZServer ]; then EXEC="/home/dayz/dayzserver/DayZServer"; else exit 1; fi; echo $EXEC > /tmp/dayz_exec'
ExecStart=/bin/bash -c '$(cat /tmp/dayz_exec) -config=/home/dayz/dayzserver/serverDZ.cfg -port=2302 -profiles=profile -freezecheck -cpuCount=2 -dologs -adminlog -netlog -scrAllowFileWrite -mission=dayz.chernarusplus'
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Habilitar serviço para iniciar automaticamente no boot (após instalação)
systemctl enable dayz-server

# Iniciar o servidor automaticamente após a instalação
echo "=== Iniciando servidor DayZ automaticamente ==="
systemctl start dayz-server || echo "Servidor será iniciado após instalação completa"

# 11. Configurar fail2ban básico
cat << 'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
EOF

systemctl enable fail2ban
systemctl start fail2ban

# 12. Otimizações do sistema para servidor de jogos
cat << 'EOF' > /etc/sysctl.d/99-dayz-optimizations.conf
# Otimizações de rede para servidor de jogos
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
EOF

sysctl -p /etc/sysctl.d/99-dayz-optimizations.conf

# 13. Mensagem final e instruções
cat << 'EOF' > /home/dayz/README.txt
=== Servidor DayZ - Instruções ===

1. Instalar o servidor DayZ:
   sudo su - dayz
   ./install_dayz.sh

2. Editar configuração:
   nano /home/dayz/dayzserver/serverDZ.cfg
   (Altere passwordAdmin e outras configurações)

3. Iniciar servidor manualmente:
   ./start_dayz.sh

4. Ou iniciar em screen:
   ./start_dayz_screen.sh
   screen -r dayz-server  # para acessar

5. Ou usar systemd service:
   sudo systemctl start dayz-server
   sudo systemctl enable dayz-server  # para iniciar no boot

6. Verificar logs:
   journalctl -u dayz-server -f
   ou
   tail -f /home/dayz/dayzserver/logs/*.log

7. Portas abertas:
   - 2302 TCP/UDP (porta principal)
   - 2303-2305 UDP (portas adicionais)

=== Informações do Sistema ===
EOF

echo "Ubuntu Version: $(lsb_release -rs)" >> /home/dayz/README.txt
echo "Build Date: $(date)" >> /home/dayz/README.txt
echo "IP Público: $(curl -s ifconfig.me)" >> /home/dayz/README.txt

chown dayz:dayz /home/dayz/README.txt

# 14. Aguardar instalação do DayZ e verificar status
echo "=== Aguardando instalação do DayZ Server ==="
sleep 30  # Aguardar um pouco para garantir que a instalação iniciou

# Verificar se o servidor foi instalado e está rodando
if [ -f /home/dayz/dayzserver/DayZServer_x64 ] || [ -f /home/dayz/dayzserver/DayZServer ]; then
  echo "✅ Servidor DayZ instalado com sucesso!"
  
  # Verificar se o serviço está rodando
  if systemctl is-active --quiet dayz-server; then
    echo "✅ Servidor DayZ está rodando!"
  else
    echo "⚠️ Servidor DayZ instalado mas não está rodando. Verifique os logs:"
    echo "   sudo journalctl -u dayz-server -n 50"
  fi
else
  echo "⚠️ Instalação do DayZ Server ainda em andamento..."
  echo "   A instalação pode levar vários minutos. Verifique o status com:"
  echo "   sudo journalctl -u dayz-server -f"
fi

# 15. Finalização
echo "=== Configuração concluída ==="
date
echo ""
echo "✅ Servidor DayZ configurado e instalado automaticamente!"
echo ""
echo "📋 Informações importantes:"
echo "   - IP Público: $(curl -s ifconfig.me)"
echo "   - Porta: 2302"
echo "   - Configuração: /home/dayz/dayzserver/serverDZ.cfg"
echo "   - Logs: sudo journalctl -u dayz-server -f"
echo ""
echo "⚠️ LEMBRE-SE:"
echo "   1. Altere a senha do admin em /home/dayz/dayzserver/serverDZ.cfg"
echo "   2. Remova a regra de segurança permissiva (0.0.0.0/0) em network.tf após testes"
echo "   3. Configure UFW para 'deny incoming' em produção"
echo ""
