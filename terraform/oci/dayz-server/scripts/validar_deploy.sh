#!/bin/bash
# Script para validar o deploy do servidor DayZ
# Uso: ./validar_deploy.sh

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=== Validação do Deploy - Servidor DayZ ==="
echo ""

# Obter IP público (executar do diretório terraform)
IP=$(cd terraform && terraform output -raw instance_public_ip 2>/dev/null || echo "")
if [ -z "$IP" ]; then
  echo -e "${RED}❌ Erro: Não foi possível obter o IP público${NC}"
  exit 1
fi

echo -e "${GREEN}✅ IP Público: $IP${NC}"
echo ""

# Verificar conectividade
echo "1. Verificando conectividade SSH..."
if ssh -i ~/.ssh/instance-oci.key -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$IP "echo 'OK'" >/dev/null 2>&1; then
  echo -e "${GREEN}✅ Servidor acessível via SSH${NC}"
else
  echo -e "${YELLOW}⚠️ Servidor ainda não acessível (aguarde mais alguns minutos)${NC}"
  exit 1
fi

echo ""
echo "2. Verificando execução do user-data.sh..."
ssh -i ~/.ssh/instance-oci.key -o StrictHostKeyChecking=no ubuntu@$IP << 'EOF'
echo "--- Log do user-data (últimas 30 linhas) ---"
if [ -f /var/log/user-data.log ]; then
  tail -30 /var/log/user-data.log
  echo ""
  if grep -q "Configuração concluída" /var/log/user-data.log; then
    echo "✅ User-data executou completamente"
  else
    echo "⚠️ User-data ainda em execução"
  fi
else
  echo "⚠️ Log do user-data ainda não disponível"
fi
EOF

echo ""
echo "3. Verificando componentes instalados..."
ssh -i ~/.ssh/instance-oci.key -o StrictHostKeyChecking=no ubuntu@$IP << 'EOF'
echo "--- Verificações ---"
echo "Usuário dayz:"
id dayz 2>/dev/null && echo "✅" || echo "❌"

echo ""
echo "SteamCMD:"
ls -la /opt/steamcmd/steamcmd.sh >/dev/null 2>&1 && echo "✅ Instalado" || echo "❌ Não encontrado"

echo ""
echo "Diretório DayZ:"
ls -d /home/dayz/dayzserver >/dev/null 2>&1 && echo "✅ Criado" || echo "❌ Não encontrado"

echo ""
echo "Instalação do DayZ Server:"
if [ -f /home/dayz/dayzserver/DayZServer_x64 ] || [ -f /home/dayz/dayzserver/DayZServer ]; then
  echo "✅ DayZ Server instalado"
  ls -lh /home/dayz/dayzserver/DayZServer* 2>/dev/null | head -1
else
  echo "⚠️ DayZ Server ainda não instalado (normal - pode levar 10-15 minutos)"
  echo "   Verificando se está em processo de instalação..."
  ps aux | grep -i steamcmd | grep -v grep && echo "   ✅ SteamCMD rodando (instalando...)" || echo "   ⚠️ SteamCMD não está rodando"
fi
EOF

echo ""
echo "4. Verificando serviço DayZ..."
ssh -i ~/.ssh/instance-oci.key -o StrictHostKeyChecking=no ubuntu@$IP << 'EOF'
if systemctl list-unit-files | grep -q dayz-server; then
  echo "Status do serviço:"
  sudo systemctl status dayz-server --no-pager 2>/dev/null | head -15 || echo "⚠️ Serviço não está rodando (normal se DayZ ainda não foi instalado)"
else
  echo "⚠️ Serviço dayz-server ainda não configurado"
fi
EOF

echo ""
echo "5. Verificando portas e firewall..."
ssh -i ~/.ssh/instance-oci.key -o StrictHostKeyChecking=no ubuntu@$IP << 'EOF'
echo "UFW Status:"
sudo ufw status | head -10

echo ""
echo "Portas abertas:"
sudo ss -tulpn | grep -E '2302|27016' || echo "⚠️ Portas DayZ ainda não abertas"
EOF

echo ""
echo "=== Resumo ==="
echo ""
echo "Para monitorar em tempo real:"
echo "  ssh -i ~/.ssh/instance-oci.key ubuntu@$IP"
echo "  sudo tail -f /var/log/user-data.log"
echo ""
echo "Para verificar instalação do DayZ:"
echo "  ssh -i ~/.ssh/instance-oci.key ubuntu@$IP"
echo "  sudo journalctl -u dayz-server -f"
echo ""
echo "Para verificar se DayZ foi instalado:"
echo "  ssh -i ~/.ssh/instance-oci.key ubuntu@$IP"
echo "  ls -la /home/dayz/dayzserver/DayZServer*"
echo ""

