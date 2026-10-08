# Scripts WAP

Índice das ferramentas. Cada pasta contém um `README.md` com objetivo, contexto de execução, parâmetros, uso, logs e limites.

Este repositório é a versão **pública** do WAP: não há caminhos de rede, servidores, IPs, DNS ou destinos de telemetria preconfigurados. Todo valor dependente do ambiente aparece como `coloque_seu_path_aqui` (ou `coloque_seu_*_aqui`) e deve ser substituído antes do uso.

Por padrão, a telemetria CSV é gravada em `C:\Temp\WAP\JsonBackup`. Todas as ferramentas que geram CSV aceitam `-TelemetryPath` (diretório local ou UNC gravável pela conta de execução) para enviar a outro local. A exceção é o `DockerInstall.cmd`, que usa a variável de ambiente `WAP_TELEMETRY_PATH`.

## Estrutura

```text
scripts/
  Executaveis/              # reparos
    Reparo avancado/
    Reparo impressoras/
    Reparo Rapido/
    Reparo SAP/
    Reparo Teams/
  Instaladores/
    ClaudeCLI/
    Dbeaver/
    Docker/
    Gitbash/
    ODBC/
    WSL/
```

## Reparos

| Ferramenta | Contexto | Documentação |
| --- | --- | --- |
| Reparo Avançado | Administrador | [README](Executaveis/Reparo%20avancado/README.md) |
| Reparo de Impressora | Administrador + usuário (2 etapas) | [README](Executaveis/Reparo%20impressoras/README.md) |
| Reparo Rápido | Administrador | [README](Executaveis/Reparo%20Rapido/README.md) |
| Reparo SAP | Usuário | [README](Executaveis/Reparo%20SAP/README.md) |
| Reparo Teams | Usuário | [README](Executaveis/Reparo%20Teams/README.md) |

## Instaladores

| Ferramenta | Contexto | Documentação |
| --- | --- | --- |
| Claude CLI | Usuário | [README](Instaladores/ClaudeCLI/README.md) |
| DBeaver | Administrador | [README](Instaladores/Dbeaver/README.md) |
| Docker CE em WSL | Usuário | [README](Instaladores/Docker/README.md) |
| Git Bash | Usuário | [README](Instaladores/Gitbash/README.md) |
| Amazon Redshift ODBC | Máquina + usuário | [README](Instaladores/ODBC/README.md) |
| WSL | SYSTEM | [README](Instaladores/WSL/README.md) |

## Observações

- Os scripts que consultam o Active Directory usam isso somente para a coluna opcional `Departamento` da telemetria. Sem módulo ou domínio AD, o valor permanece `Unknown` e a execução continua.
- Teste os scripts em uma máquina de homologação antes de qualquer deploy em massa.
- Nunca versione arquivos com hosts, credenciais, tokens ou dados reais do seu ambiente.