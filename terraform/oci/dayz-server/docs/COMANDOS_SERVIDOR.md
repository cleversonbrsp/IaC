# 🎮 Comandos Úteis - Servidor DayZ

## 📍 Informações de Conexão

**IP Público do Servidor**: `137.131.231.155`  
**Porta**: `2302`  
**SSH**: `ssh -i ~/.ssh/instance-oci.key ubuntu@137.131.231.155`

---

## 🚀 Gerenciamento do Servidor (Systemd)

### Iniciar o Servidor
```bash
ssh -i ~/.ssh/instance-oci.key ubuntu@137.131.231.155
sudo systemctl start dayz-server
```

### Parar o Servidor
```bash
sudo systemctl stop dayz-server
```

### Reiniciar o Servidor
```bash
sudo systemctl restart dayz-server
```

### Ver Status do Servidor
```bash
sudo systemctl status dayz-server
```

### Ver Logs em Tempo Real
```bash
sudo journalctl -u dayz-server -f
```

### Ver Últimos 100 Logs
```bash
sudo journalctl -u dayz-server -n 100
```

### Habilitar Inicialização Automática (Já está habilitado!)
```bash
sudo systemctl enable dayz-server
```

### Desabilitar Inicialização Automática
```bash
sudo systemctl disable dayz-server
```

---

## 📊 Verificar se o Servidor Está Rodando

### Verificar Porta 2302
```bash
sudo ss -tulpn | grep 2302
```

### Verificar Processo
```bash
ps aux | grep DayZServer | grep -v grep
```

### Verificar Uso de Recursos
```bash
htop
# Pressione 'q' para sair
```

---

## 📋 Logs do DayZ

### Logs do Servidor DayZ
```bash
sudo su - dayz
cd /home/dayz/dayzserver
tail -f profile/error.log
```

### Ver Último Log RPT
```bash
ls -lth profile/*.RPT | head -1 | awk '{print $NF}' | xargs tail -50
```

### Ver Todos os Logs Recentes
```bash
ls -lth profile/*.RPT | head -5
```

---

## ⚙️ Configuração

### Editar Configuração do Servidor
```bash
sudo su - dayz
nano /home/dayz/dayzserver/serverDZ.cfg
# Após editar, reinicie o servidor:
sudo systemctl restart dayz-server
```

### Ver Configuração Atual
```bash
sudo su - dayz
cat /home/dayz/dayzserver/serverDZ.cfg
```

---

## 🔄 Atualizar o Servidor DayZ

### Atualizar via SteamCMD
```bash
sudo su - dayz
cd /opt/steamcmd
./steamcmd.sh +force_install_dir /home/dayz/dayzserver +login thefly72003 +app_update 223350 validate +quit
sudo systemctl restart dayz-server
```

---

## 🛠️ Troubleshooting

### Servidor não inicia
```bash
# Ver logs detalhados
sudo journalctl -u dayz-server -n 50

# Verificar se instanceId está no config
sudo su - dayz
grep instanceId /home/dayz/dayzserver/serverDZ.cfg
```

### Servidor parou inesperadamente
```bash
# Ver logs de erro
sudo journalctl -u dayz-server --since "10 minutes ago"

# Verificar se há espaço em disco
df -h

# Verificar memória
free -h
```

### Reiniciar tudo (último recurso)
```bash
sudo systemctl stop dayz-server
sudo systemctl start dayz-server
sudo systemctl status dayz-server
```

---

## 🌐 Conectar no Jogo

No DayZ, adicione o servidor:
- **IP**: `137.131.231.155`
- **Porta**: `2302`
- **Nome**: "Juse DayZ Server"

Ou procure na lista de servidores pelo nome "Juse DayZ Server".

---

## ✅ Checklist de Verificação Rápida

```bash
# 1. Servidor está rodando?
sudo systemctl is-active dayz-server

# 2. Porta está aberta?
sudo ss -tulpn | grep 2302

# 3. Processo está ativo?
ps aux | grep DayZServer | grep -v grep

# 4. Serviço habilitado no boot?
sudo systemctl is-enabled dayz-server
```

Todos devem retornar resultados positivos! ✅

