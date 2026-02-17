# Scripts

Esta pasta contém scripts de automação para o servidor DayZ.

## Scripts

- `user-data.sh` - Script executado automaticamente na inicialização da instância
  - Instala dependências (SteamCMD, bibliotecas)
  - Cria usuário `dayz`
  - Configura firewall e segurança
  - Instala e inicia o servidor DayZ automaticamente

- `validar_deploy.sh` - Script para validar o deploy
  - Verifica conectividade SSH
  - Verifica se o servidor DayZ está rodando
  - Valida configurações

## Uso

O `user-data.sh` é referenciado automaticamente pelo Terraform em `terraform/instances.tf`.

Para validar o deploy:
```bash
./scripts/validar_deploy.sh
```
