# Instalador Docker CE em WSL

## Responsabilidade

Aplicativo SCCM de usuario, independente do instalador WSL. Importa a distro Ubuntu `Ubuntu` no perfil do usuario a partir de uma imagem corporativa que ja contem Docker CE, Compose, systemd, certificado e configuracao DNS. Nao instala runtime WSL, recursos Windows, Docker Desktop ou pacotes via apt.

## Fluxo

1. Confirma identidade de usuario e disponibilidade do runtime WSL.
2. Reutiliza uma distro existente sem remove-la; se nao existir, localiza e importa a imagem como WSL2.
3. Valida systemd, Docker, Compose e resposta do daemon.
4. Instala o script first-run; a entrada CMD configura DNS corporativo e fallback durante a instalacao.
5. Grava flag de conclusao somente depois das validacoes.

A conclusao Windows nao cria a conta Linux: no primeiro acesso interativo, o usuario define nome e senha. A distro existente que falha validacao nao e apagada nem reimportada automaticamente.

## Entradas e limites

Implementacao: `scripts/Instaladores/Docker/Script/`. O `.cmd` e autonomo e nao exporta CSV; o caminho PowerShell gera telemetria CSV. Ambos devem executar como usuario, nao SYSTEM. A imagem, deteccao SCCM, cache, logs, homologacao e comandos estao no [guia tecnico Docker](../scripts/Instaladores/Docker/README-Instalacao-Docker-WAP.md).

Estimativa de economia: 20 minutos por instalacao bem-sucedida. Isso e uma referencia historica de ROI; WSL e contabilizado separadamente.
