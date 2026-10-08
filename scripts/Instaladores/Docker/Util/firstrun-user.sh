#!/usr/bin/env bash
# ==================================================================================
# WAP - First Run (OOBE) da distro Ubuntu
# Objetivo: replicar a experiencia nativa do Ubuntu da Store.
#   - O instalador Docker importa a distro no perfil Windows do usuario, como root.
#   - Este script dispara quando o USUARIO abre o terminal pela 1a vez (interativo)
#     e pede USER + SENHA na hora, cria o usuario, poe no sudo + docker e define
#     como default via /etc/wsl.conf. Da 2a vez em diante ja loga com ele.
#
# Instalacao: colocado em /etc/profile.d/00-wap-firstrun.sh dentro da distro
#             (roda automaticamente em todo shell de login enquanto o flag nao existir)
# ==================================================================================

FLAG="/etc/wap-firstrun.done"
PENDING_USER="/etc/wap-firstrun.pending-user"

# Troque pelo DNS interno da sua organizacao; mantido o placeholder, so o fallback publico e usado.
WAP_CORPORATE_DNS="coloque_seu_dns_aqui"
WAP_FALLBACK_DNS="1.1.1.1"

wap_configure_network() {
    local dns="$WAP_FALLBACK_DNS" server
    if [ "$WAP_CORPORATE_DNS" != "coloque_seu_dns_aqui" ]; then
        dns="$WAP_CORPORATE_DNS $WAP_FALLBACK_DNS"
    fi
    mkdir -p /etc/systemd/resolved.conf.d
    printf '[Resolve]\nDNS=%s\n' "$dns" > /etc/systemd/resolved.conf.d/wap-dns.conf
    systemctl restart systemd-resolved
    rm -f /etc/resolv.conf
    for server in $dns; do printf 'nameserver %s\n' "$server"; done > /etc/resolv.conf
}

if [ "${1:-}" = "--configure-network" ]; then
    set -euo pipefail
    [ "$(id -u)" -eq 0 ]
    wap_configure_network
    exit 0
fi

# Ja configurado? sai na hora (nao atrapalha logins futuros)
if [ -f "$FLAG" ]; then return 0 2>/dev/null || exit 0; fi

# So roda se estivermos como root (estado inicial da distro importada)
if [ "$(id -u)" -ne 0 ]; then return 0 2>/dev/null || exit 0; fi
if [ ! -t 0 ] || [ ! -t 1 ]; then return 0 2>/dev/null || exit 0; fi

(
set -euo pipefail
clear
cat <<'BANNER'
============================================================
   WAP - Configuracao inicial do seu ambiente Docker (WSL)
============================================================
 Vamos criar seu usuario Linux. Ele sera o dono do ambiente,
 tera permissao de sudo e podera usar o Docker.
------------------------------------------------------------
BANNER

# ---- Sugere o proprio usuario do Windows como padrao ----------------------------
WINUSER="$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9._-')"

# ---- 1) Nome de usuario ---------------------------------------------------------
while true; do
    read -rp "Nome de usuario [${WINUSER:-usuario}]: " NEWUSER
    NEWUSER="${NEWUSER:-$WINUSER}"
    if echo "$NEWUSER" | grep -Eq '^[a-z_][a-z0-9_-]{0,31}$'; then
        if id "$NEWUSER" >/dev/null 2>&1; then
            if [ ! -f "$PENDING_USER" ] || [ "$(cat "$PENDING_USER")" != "$NEWUSER" ]; then
                echo ">> Usuario ja existe. Escolha outro nome; nenhuma senha existente sera alterada."
                continue
            fi
        fi
        break
    fi
    echo ">> Invalido. Use minusculas, sem espacos (ex.: vinicius.silva -> vinicius_silva)."
done

# ---- 2) Senha (com confirmacao, digitacao cega) ---------------------------------
while true; do
    read -rsp "Senha: " PW1; echo
    read -rsp "Confirme a senha: " PW2; echo
    if [ -z "$PW1" ]; then echo ">> A senha nao pode ser vazia."; continue; fi
    if [ "$PW1" != "$PW2" ]; then echo ">> As senhas nao conferem, tente de novo."; continue; fi
    break
done

# ---- 3) Cria o usuario, define senha e permissoes -------------------------------
echo ">> Criando usuario '$NEWUSER'..."
if ! id "$NEWUSER" >/dev/null 2>&1; then
    printf '%s\n' "$NEWUSER" > "$PENDING_USER"
    adduser --gecos "" --disabled-password "$NEWUSER"
fi
echo "${NEWUSER}:${PW1}" | chpasswd
unset PW1 PW2
usermod -aG sudo "$NEWUSER"      # administrador (sudo)
groupadd -f docker
usermod -aG docker "$NEWUSER"    # pode usar docker sem sudo

# ---- 4) DNS corporativo (generateResolvConf=false exige DNS estatico) ----------
echo ">> Configurando DNS (corporativo + fallback)..."
wap_configure_network

# ---- 5) Define como usuario default via wsl.conf --------------------------------
{
    echo "[boot]"
    echo "systemd=true"
    echo "[network]"
    echo "generateResolvConf=false"
    echo "[user]"
    echo "default=${NEWUSER}"
} > /etc/wsl.conf

# ---- 6) Marca como concluido e encerra a distro p/ aplicar o wsl.conf ------------
id "$NEWUSER" >/dev/null
id -nG "$NEWUSER" | tr ' ' '\n' | grep -qx sudo
id -nG "$NEWUSER" | tr ' ' '\n' | grep -qx docker
docker info >/dev/null
rm -f "$PENDING_USER"
touch "$FLAG"
cat <<MSG

============================================================
 Pronto, ${NEWUSER}! Ambiente configurado com sucesso.
 A distro vai reiniciar para aplicar suas configuracoes.
 Abra o terminal novamente e voce ja entrara como ${NEWUSER}.

Como iniciar a distro no terminal do Windows:
    wsl -d ${WSL_DISTRO_NAME}

Validacoes recomendadas dentro do Ubuntu:
    whoami
    id
    sudo docker run hello-world

O teste hello-world confirma usuario, sudo, Docker, DNS e acesso ao Docker Hub.
Leia os comandos acima; a distro sera encerrada em 10 segundos.
============================================================
MSG
sleep 10
# encerra a propria distro (regra dos 8s / aplica o default user)
( sleep 1; /mnt/c/Windows/System32/wsl.exe --terminate "$WSL_DISTRO_NAME" ) >/dev/null 2>&1 &
exit 0
)
WAP_FIRST_RUN_RESULT=$?
if [ "$WAP_FIRST_RUN_RESULT" -ne 0 ]; then
    echo 'ERRO: configuracao inicial incompleta. A flag nao foi gravada; corrija a falha antes de tentar novamente.'
    return "$WAP_FIRST_RUN_RESULT" 2>/dev/null || exit "$WAP_FIRST_RUN_RESULT"
fi
return 0 2>/dev/null || exit 0
