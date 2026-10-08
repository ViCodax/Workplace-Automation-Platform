#!/usr/bin/env bash
# Primeiro acesso da distribuicao WSL. A imagem deve conter Docker e systemd configurado.

FLAG="/etc/wap-firstrun.done"
[ -f "$FLAG" ] && return 0 2>/dev/null || true
[ "$(id -u)" -ne 0 ] && return 0 2>/dev/null || true

read -rp "Nome de usuario Linux: " NEWUSER
if ! echo "$NEWUSER" | grep -Eq '^[a-z_][a-z0-9_-]{0,31}$'; then
  echo "Nome invalido. Use letras minusculas, numeros, _ ou -."
  return 1
fi

while true; do
  read -rsp "Senha: " PW1; echo
  read -rsp "Confirme a senha: " PW2; echo
  [ -n "$PW1" ] && [ "$PW1" = "$PW2" ] && break
  echo "As senhas estao vazias ou nao conferem."
done

adduser --gecos "" --disabled-password "$NEWUSER"
echo "$NEWUSER:$PW1" | chpasswd
usermod -aG sudo "$NEWUSER"
groupadd -f docker
usermod -aG docker "$NEWUSER"
printf '[boot]\nsystemd=true\n[user]\ndefault=%s\n' "$NEWUSER" > /etc/wsl.conf
touch "$FLAG"
echo "Configuracao concluida. Feche e abra a distribuicao novamente."