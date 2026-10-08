# Instalador Docker CE em WSL

Importa uma distribuição Ubuntu no perfil do usuário a partir de uma imagem que já contém Docker CE, Compose e systemd. Não instala o runtime WSL, recursos do Windows, Docker Desktop nem pacotes via `apt`.

| Item | Valor |
|---|---|
| Entradas | `Script/DockerInstall.cmd` (autônomo, sem CSV) e `Script/DockerInstall.ps1` (com telemetria CSV) |
| Contexto | Usuário (nunca SYSTEM) |
| Pré-requisito | Runtime WSL instalado (veja [`../WSL`](../WSL/README.md)) |
| Economia estimada | 20 minutos por instalação bem-sucedida |

## Estrutura

```text
Docker/
  Script/
    DockerInstall.cmd          # entrada autônoma (log, sem CSV)
    DockerInstall.ps1          # entrada PowerShell (log + CSV)
    DockerInstall-Usuario.ps1  # wrapper por usuário
    DockerFase2-Usuario.ps1    # etapa por usuário
    DockerLog.js               # conversão de logs para UTF-8
  Util/
    firstrun-user.sh           # primeiro acesso (cria usuário e senha)
    provision-docker.sh        # provisionamento da imagem base
    Cloudflare_CA.pem          # NAO incluido: forneca o certificado raiz da sua organizacao
  old version/                 # fluxo legado em duas fases (referência histórica)
  README-Instalacao-Docker-WAP.md   # guia técnico completo e homologação
```

## Configuração antes de usar

Substitua os valores `coloque_seu_path_aqui` e `coloque_seu_dns_aqui`:

| Arquivo | Variável | O que informar |
|---|---|---|
| `Script/DockerInstall.cmd` | `NETWORK_PAYLOAD` | Pasta com `firstrun-user.sh` e demais itens de `Util` |
| `Script/DockerInstall.cmd` | `ROOTFS_SOURCE` | Caminho da imagem `ubuntu-wap.wsl` (também aceito como primeiro argumento) |
| `Script/DockerInstall.cmd` | variável de ambiente `WAP_TELEMETRY_PATH` | Destino do CSV (opcional; sem ele, só o fallback local é usado) |
| `Script/DockerInstall.ps1` (e wrappers `*-Usuario.ps1`) | `-RootfsSourcePath`, `-TelemetryPath` | Imagem e destino do CSV (opcional; padrão: `%LOCALAPPDATA%\WAP\JsonBackup`) |
| `Script/DockerInstall.ps1` | `$NetworkUtilSource` | Pasta `Util` na rede (opcional) |
| `Util/firstrun-user.sh` | `WAP_CORPORATE_DNS` | DNS interno (opcional; sem ele só o fallback `1.1.1.1` é aplicado) |

A imagem `ubuntu-wap.wsl` deve ser criada e homologada pela sua organização, com Docker já instalado.

### Itens a fornecer

| Item | Descrição |
|---|---|
| `ubuntu-wap.wsl` | Imagem WSL da sua organização, com Docker CE, Compose e systemd |
| `Util/Cloudflare_CA.pem` | Certificado raiz da sua organização, se a rede intercepta TLS (proxy, WARP etc.). O arquivo não é distribuído no repositório; `provision-docker.sh` o instala na imagem base quando presente |

## Uso

Via CMD (recomendado onde o PowerShell não está disponível):

```bat
Script\DockerInstall.cmd --check-only
Script\DockerInstall.cmd "coloque_seu_path_aqui\ubuntu-wap.wsl"
```

`--check-only` valida contexto de usuário e runtime WSL sem importar ou alterar nenhuma distro. Retorno `0` = sucesso, `1` = falha.

## Fluxo

1. Confirma identidade de usuário e disponibilidade do runtime WSL.
2. Reutiliza uma distro existente sem removê-la; se não existir, localiza e importa a imagem como WSL2.
3. Valida systemd, Docker, Compose e resposta do daemon.
4. Instala o *first-run* e configura o DNS.
5. Grava a flag de conclusão somente após as validações.

A conta Linux não é criada na instalação: no primeiro acesso interativo o usuário define nome e senha. Uma distro existente que falha na validação não é apagada nem reimportada automaticamente.

## Logs e telemetria

- `DockerInstall.cmd`: `C:\Temp\WAP\Logs\WAP_DockerInstall.log` (não exporta CSV).
- `DockerInstall.ps1`: log em `%LOCALAPPDATA%\WAP\Logs` e CSV `DockerInstall_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.csv`, com fallback local.

Detalhes, contrato SCCM e resultados de homologação: [`README-Instalacao-Docker-WAP.md`](README-Instalacao-Docker-WAP.md) · Guia institucional: [`wap/Instalador-Docker.md`](../../../wap/Instalador-Docker.md)
