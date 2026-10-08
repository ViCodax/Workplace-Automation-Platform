# Instalador Git Bash

## Objetivo

Instalar Git for Windows (inclui Git Bash) e validar que o executavel Git responde.

## O que faz

- Verifica se `git --version` ja funciona.
- Tenta instalar `Git.Git` pelo WinGet.
- Na variante por usuario, se WinGet falhar ou nao estiver disponivel, consulta a release oficial do Git for Windows e executa o instalador silencioso.
- Valida novamente a presenca e versao do Git.

## Implementacao

Os arquivos estao em `scripts/Instaladores/Gitbash/`: o wrapper de maquina encaminha para a variante por usuario.

A variante por usuario grava log em `C:\Temp\WAP\Logs\WAP_GitBashInstall.log` e exporta telemetria CSV. Estimativa de economia: 5 minutos por instalacao.
