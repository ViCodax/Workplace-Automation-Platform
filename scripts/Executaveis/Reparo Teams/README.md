# Reparo Microsoft Teams

Recupera o novo Microsoft Teams encerrando processos, removendo o cache local e solicitando a reabertura do aplicativo.

| Item | Valor |
|---|---|
| Script | `WAP-ReparoTeams.ps1` |
| Contexto | Usuário cujo Teams será reparado |
| Privilégios | Não exige administrador |
| Reinicialização | Não |
| Economia estimada | 5 minutos por execução bem-sucedida |

## O que faz

1. Encerra os processos `ms-teams`, `teams`, `msteams` e `msedgewebview2`.
2. Remove o cache em `%LOCALAPPDATA%\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams`, com novas tentativas se a pasta persistir.
3. Tenta reabrir o Teams pelos protocolos `msteams:`, `ms-teams:` e `teams:`.

## Parâmetros

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `-TelemetryPath` | Não | Diretório (ou UNC) de destino do CSV. Padrão: `C:\Temp\WAP\JsonBackup`. Use `coloque_seu_path_aqui` como referência para o seu ambiente. |

## Uso

```powershell
.\WAP-ReparoTeams.ps1
.\WAP-ReparoTeams.ps1 -TelemetryPath 'coloque_seu_path_aqui'
```

## Logs e telemetria

- Log: `C:\Temp\WAP\Logs\WAP_ReparoTeams.log`
- CSV: `ReparoTeams_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.csv`, com fallback local em `C:\Temp\WAP\JsonBackup`.

## Limites

- Se nenhum protocolo estiver registrado, as tentativas são registradas, mas o script não valida que a interface do Teams abriu.
- Atua somente no novo Teams (pacote `MSTeams_8wekyb3d8bbwe`).

Guia institucional: [`wap/Reparo-Teams.md`](../../../wap/Reparo-Teams.md)
