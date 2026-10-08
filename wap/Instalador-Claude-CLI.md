# Instalador Claude CLI

## Objetivo

Instalar e validar o Claude Code CLI para o usuario Windows detectado.

## O que faz

- Procura `claude.exe` nos locais conhecidos do perfil do usuario e valida `claude --version`.
- Quando necessario, tenta WinGet no contexto interativo do usuario por meio de uma tarefa agendada de uso unico.
- Se isso nao concluir, tenta WinGet no contexto do processo e, por fim, o instalador oficial `claude.ai/install.cmd`.
- Faz nova verificacao do executavel apos instalar.

## Implementacao

O script esta em `scripts/Instaladores/ClaudeCLI/`.

Log em `C:\Temp\WAP\Logs\WAP_ClaudeIIIInstall.log`; telemetria CSV central com fallback local. A instalacao pode depender de internet, WinGet e de uma sessao de usuario ativa. Estimativa de economia: 10 minutos por instalacao.
