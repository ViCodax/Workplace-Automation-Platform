# Instalador Claude CLI

Instala e valida o Claude Code CLI para o usuário Windows atual.

| Item | Valor |
|---|---|
| Script | `WAP-ClaudeIII-Install.ps1` |
| Contexto | Usuário |
| Pré-requisitos | Internet, WinGet (ou acesso a `claude.ai`) e sessão de usuário ativa |
| Economia estimada | 10 minutos por instalação bem-sucedida |

## O que faz

1. Procura `claude.exe` nos locais conhecidos do perfil e valida `claude --version`.
2. Quando necessário, tenta o WinGet no contexto interativo do usuário por meio de uma tarefa agendada de uso único.
3. Se não concluir, tenta o WinGet no contexto do processo e, por fim, o instalador oficial `claude.ai/install.cmd`.
4. Verifica novamente o executável após instalar.

## Parâmetros

Nenhum.

## Uso

```powershell
.\WAP-ClaudeIII-Install.ps1
```

## Logs

- Log: `C:\Temp\WAP\Logs\WAP_ClaudeIIIInstall.log`

Guia institucional: [`wap/Instalador-Claude-CLI.md`](../../../wap/Instalador-Claude-CLI.md)
