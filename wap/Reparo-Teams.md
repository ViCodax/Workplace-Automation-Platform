# Reparo Microsoft Teams

## Objetivo

Tentar recuperar o novo Microsoft Teams encerrando processos, removendo cache local e solicitando a abertura do aplicativo.

## O que faz

- Encerra `ms-teams`, `teams`, `msteams` e `msedgewebview2`.
- Remove o cache em `AppData\Local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams`, com novas tentativas se a pasta persistir.
- Tenta iniciar o Teams pelos protocolos `msteams:`, `ms-teams:` e `teams:`.

## Execucao e limites

Implementacao: `scripts/Executaveis/Reparo Teams/WAP-ReparoTeams.ps1`. Deve operar no contexto do usuario cujo Teams e cache serao tratados. Se nenhum protocolo estiver registrado, o script registra as tentativas, mas nao valida que a interface do Teams abriu.

Log: `C:\Temp\WAP\Logs\WAP_ReparoTeams.log`. Telemetria CSV central com fallback local. Estimativa de economia: 5 minutos por execucao bem-sucedida.
