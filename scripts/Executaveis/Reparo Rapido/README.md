# Reparo Rápido do Windows

Aplica correções comuns de rede e limpeza local em uma única rotina.

| Item | Valor |
|---|---|
| Script | `WAP-ReparoRapido.ps1` |
| Contexto | Máquina |
| Privilégios | Administrador |
| Reinicialização | Pode ser necessária após o reset de rede |
| Economia estimada | 20 minutos por execução bem-sucedida |

## O que faz

- Limpa o cache DNS e solicita reset de Winsock e TCP/IP.
- Limpa o conteúdo de `%TEMP%` do processo e de `C:\Windows\Temp`.
- Encerra processos do Teams, remove o cache local do novo Teams (quando presente) e reinicia o Explorer.
- Registra uptime, IPv4 e espaço livre no log; exporta o uptime no CSV.

## Parâmetros

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `-TelemetryPath` | Não | Diretório (ou UNC) de destino do CSV. Padrão: `C:\Temp\WAP\JsonBackup`. Use `coloque_seu_path_aqui` como referência para o seu ambiente. |

## Uso

```powershell
.\WAP-ReparoRapido.ps1
.\WAP-ReparoRapido.ps1 -TelemetryPath 'coloque_seu_path_aqui'
```

## Logs e telemetria

- Log: `C:\Temp\WAP\Logs\WAP_ReparoRapido.log`
- CSV: `ReparoRapido_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.csv`, com fallback local em `C:\Temp\WAP\JsonBackup`.

## Limites

- A limpeza é *best-effort* para itens bloqueados.
- O script não confirma individualmente o sucesso de cada comando externo.

Guia institucional: [`wap/Reparo-Rapido.md`](../../../wap/Reparo-Rapido.md)
