# Documentacao WAP

Este e o indice da documentacao institucional. Consulte o guia da ferramenta para saber o que ela faz, como e distribuida e quais limites importam. Cada pasta de script em `../scripts/` tem tambem um `README.md` com parametros e exemplos de uso. Dados do ambiente (caminhos, servidores) aparecem como `coloque_seu_path_aqui`.

## Desenvolvimento de novos scripts

- [Padrao oficial WAP para novos scripts](Padrao-Oficial-WAP.md): auditoria dos padroes recorrentes, contrato de telemetria e excecoes por contexto.

## Reparos

| Ferramenta | Guia | Implementacao |
|---|---|---|
| Reparo avancado do Windows | [Reparo avancado](Reparo-Avancado.md) | [`scripts/Executaveis/Reparo avancado/`](../scripts/Executaveis/Reparo%20avancado/README.md) |
| Reparo de impressora | [Impressora](Reparo-Impressora.md) | [`scripts/Executaveis/Reparo impressoras/`](../scripts/Executaveis/Reparo%20impressoras/README.md) |
| Reparo rapido do Windows | [Reparo rapido](Reparo-Rapido.md) | [`scripts/Executaveis/Reparo Rapido/`](../scripts/Executaveis/Reparo%20Rapido/README.md) |
| Reparo SAP | [SAP](Reparo-SAP.md) | [`scripts/Executaveis/Reparo SAP/`](../scripts/Executaveis/Reparo%20SAP/README.md) |
| Reparo Microsoft Teams | [Teams](Reparo-Teams.md) | [`scripts/Executaveis/Reparo Teams/`](../scripts/Executaveis/Reparo%20Teams/README.md) |

## Instalacao e ambiente de desenvolvimento

| Ferramenta | Guia | Implementacao |
|---|---|---|
| Runtime WSL | [Instalador WSL](Instalador-WSL.md) | [`scripts/Instaladores/WSL/`](../scripts/Instaladores/WSL/README.md) |
| Docker CE em WSL | [Instalador Docker](Instalador-Docker.md) | [`scripts/Instaladores/Docker/`](../scripts/Instaladores/Docker/README.md) |
| DBeaver | [Instalador DBeaver](Instalador-DBeaver.md) | [`scripts/Instaladores/Dbeaver/`](../scripts/Instaladores/Dbeaver/README.md) |
| Git Bash | [Instalador Git Bash](Instalador-GitBash.md) | [`scripts/Instaladores/Gitbash/`](../scripts/Instaladores/Gitbash/README.md) |
| Claude CLI | [Instalador Claude CLI](Instalador-Claude-CLI.md) | [`scripts/Instaladores/ClaudeCLI/`](../scripts/Instaladores/ClaudeCLI/README.md) |
| Amazon Redshift ODBC | n/d | [`scripts/Instaladores/ODBC/`](../scripts/Instaladores/ODBC/README.md) |

## Visao do projeto

A [apresentacao institucional](Apresentacao-WAP.md) explica o problema atendido, os objetivos, o modelo de distribuicao e os criterios de evolucao. Ela nao substitui os guias tecnicos individuais.

## Referencias complementares

- [Power BI: telemetria CSV](PowerBI.md)
- [Instalacao Docker: contrato e homologacao](../scripts/Instaladores/Docker/README-Instalacao-Docker-WAP.md)
- [Instalacao WSL: contrato e homologacao](../scripts/Instaladores/WSL/README.md)
- `BACKUPS/`, `default/` e documentos de auditoria em `Misc/` sao referencias historicas ou genericas, nao a fonte do comportamento atual.
