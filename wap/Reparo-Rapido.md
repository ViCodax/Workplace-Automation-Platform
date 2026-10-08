# Reparo rapido do Windows

## Objetivo

Aplicar correcoes comuns de rede e limpeza local em uma unica rotina.

## O que faz

- Limpa o cache DNS e solicita reset de Winsock e TCP/IP.
- Limpa os conteudos de `%TEMP%` do processo e de `C:\Windows\Temp`.
- Encerra processos do Teams, remove o cache local do novo Teams quando presente e reinicia o Explorer.
- Registra uptime, IPv4 e espaco livre no log; exporta uptime no CSV WAP.

## Execucao e limites

Implementacao: `scripts/Executaveis/Reparo Rapido/WAP-ReparoRapido.ps1`. Os resets de rede podem exigir reinicializacao para surtir efeito completo. A limpeza e best-effort para itens bloqueados; o script nao confirma individualmente o sucesso de cada comando externo.

Log: `C:\Temp\WAP\Logs\WAP_ReparoRapido.log`. Telemetria CSV central com fallback local. Estimativa de economia: 20 minutos por execucao bem-sucedida.
