# Instalador Git Bash

Instala o Git for Windows (inclui o Git Bash) e valida que o executável responde.

| Item | Valor |
|---|---|
| Scripts | `WAP-GitBash-Install-Usuario.ps1` (instalação) e `WAP-GitBash-Install.ps1` (wrapper de máquina) |
| Contexto | Usuário |
| Pré-requisitos | Internet e WinGet |
| Economia estimada | 5 minutos por instalação bem-sucedida |

## O que faz

1. Verifica se `git --version` já funciona.
2. Tenta instalar `Git.Git` pelo WinGet.
3. Na variante por usuário, se o WinGet falhar ou não estiver disponível, consulta a release oficial do Git for Windows e executa o instalador silencioso.
4. Valida novamente a presença e a versão do Git.

O wrapper `WAP-GitBash-Install.ps1` apenas encaminha para a variante por usuário. Em deploys de máquina, agende a variante por usuário após o logon.

## Parâmetros

Nenhum.

## Uso

```powershell
.\WAP-GitBash-Install-Usuario.ps1
```

## Logs

- Log: `C:\Temp\WAP\Logs\WAP_GitBashInstall.log`

Guia institucional: [`wap/Instalador-GitBash.md`](../../../wap/Instalador-GitBash.md)
