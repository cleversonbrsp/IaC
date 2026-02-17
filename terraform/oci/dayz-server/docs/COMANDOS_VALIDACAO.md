# 🔍 Comandos de Validação do Deploy

## Informações do Servidor

- **IP Público**: `137.131.154.107`
- **Comando SSH**: `ssh -i ~/.ssh/instance-oci.key ubuntu@137.131.154.107`

## ✅ Checklist de Validação

### 1. Verificar se user-data executou completamente

```bash
ssh -i ~/.ssh/instance-oci.key ubuntu@137.131.154.107
sudo tail -f /var/log/user-data.log
```

**Procure por**: `"Configuração concluída"` ou `"Servidor DayZ configurado com sucesso!"`

### 2. Verificar componentes instalados

```bash
# Verificar usuário dayz
id dayz

# Verificar SteamCMD
ls -la /opt/steamcmd/steamcmd.sh

# Verificar diretórios
ls -la /home/dayz/
ls -la /home/dayz/dayzserver/
```

### 3. Verificar instalação do DayZ Server

```bash
# Verificar se DayZ foi instalado
ls -la /home/dayz/dayzserver/DayZServer*
# ou
ls -la /home/dayz/dayzserver/DayZServer

# Verificar tamanho (deve ser ~4GB+)
du -sh /home/dayz/dayzserver/
```

### 4. Verificar serviço DayZ

```bash
# Status do serviço
sudo systemctl status dayz-server

# Ver logs em tempo real
sudo journalctl -u dayz-server -f

# Ver últimos logs
sudo journalctl -u dayz-server -n 100
```

### 5. Verificar firewall e portas

```bash
# Status do UFW
sudo ufw status

# Portas abertas
sudo ss -tulpn | grep -E '2302|27016'

# Testar conectividade
sudo netstat -tulpn | grep 2302
```

### 6. Verificar processos

```bash
# Processos DayZ
ps aux | grep DayZServer | grep -v grep

# Processos SteamCMD
ps aux | grep steamcmd | grep -v grep

# Uso de recursos
htop
# ou
top
```

## ⚠️ Se a Instalação Automática Falhou

### Login Steam Manual (Recomendado)

Como você configurou `steam_username = "thefly72003"` sem senha, você precisa autenticar manualmente:

```bash
# 1. Acesse o servidor
ssh -i ~/.ssh/instance-oci.key ubuntu@137.131.154.107

# 2. Troque para usuário dayz
sudo su - dayz

# 3. Execute SteamCMD
cd /opt/steamcmd
./steamcmd.sh +login thefly72003 +force_install_dir /home/dayz/dayzserver +app_update 223350 validate +quit

# 4. Quando solicitado:
#    - Digite sua senha do Steam (não aparecerá na tela)
#    - Se tiver Steam Guard, digite o código do email/app
```

### Após Instalação Bem-Sucedida

```bash
# Verificar se foi instalado
ls -la /home/dayz/dayzserver/DayZServer*

# Garantir permissões
chmod +x /home/dayz/dayzserver/DayZServer_x64 2>/dev/null || true
chmod +x /home/dayz/dayzserver/DayZServer 2>/dev/null || true

# Iniciar o servidor
sudo systemctl start dayz-server
sudo systemctl enable dayz-server

# Verificar status
sudo systemctl status dayz-server
```

## 📊 Monitoramento em Tempo Real

### Logs do User-Data
```bash
sudo tail -f /var/log/user-data.log
```

### Logs do DayZ Server
```bash
sudo journalctl -u dayz-server -f
```

### Logs do SteamCMD
```bash
tail -f /home/dayz/Steam/logs/stderr.txt
```

## 🔧 Comandos Úteis

### Reiniciar o servidor DayZ
```bash
sudo systemctl restart dayz-server
```

### Parar o servidor DayZ
```bash
sudo systemctl stop dayz-server
```

### Verificar uso de recursos
```bash
htop
# ou
free -h
df -h
```

### Verificar conectividade externa
```bash
# Do seu computador (não do servidor)
telnet 137.131.154.107 2302
# ou
nc -u -v 137.131.154.107 2302
```

## ✅ Validação Completa

Execute o script de validação:
```bash
./validar_deploy.sh
```

Este script verifica automaticamente todos os componentes e mostra um resumo do status.

