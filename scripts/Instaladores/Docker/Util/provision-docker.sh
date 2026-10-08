#!/usr/bin/env bash
# ==================================================================================
# WAP - provisionamento do Docker CE dentro da distro Ubuntu (WSL2)
# Executado como root para preparar a imagem base, nao pelo instalador Windows.
# Segue a padronizacao homologada da organizacao
# (Docker CLI via WSL2 - Docker Desktop NAO e homologado).
# ==================================================================================
set -euo pipefail

# --- Certificado Cloudflare/WARP (copie Cloudflare_CA.pem p/ C:\WAP\Docker) --------
if [ -f /mnt/c/WAP/Docker/Cloudflare_CA.pem ]; then
    echo ">> Instalando certificado Cloudflare_CA ..."
    cp /mnt/c/WAP/Docker/Cloudflare_CA.pem /usr/local/share/ca-certificates/Cloudflare_CA.crt
    update-ca-certificates
fi

# --- Repositorio oficial do Docker (metodo keyring atual, sem apt-key) ------------
echo ">> Configurando repositorio do Docker ..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg apt-transport-https software-properties-common

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

# --- Instala Docker CE + Compose plugin -------------------------------------------
echo ">> Instalando docker-ce ..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- Grupo docker (usuario final e adicionado no 1o acesso) -----------------------
groupadd -f docker

# --- Validacao rapida --------------------------------------------------------------
echo ">> Validando servico ..."
service docker start || true
docker --version || true

echo ">> Docker CE provisionado com sucesso."
