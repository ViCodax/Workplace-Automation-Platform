# Instalador Amazon Redshift ODBC

Instala o driver Amazon Redshift ODBC (x64) e, em uma etapa separada de usuário, importa o DSN e a lista de fontes de dados.

| Item | Etapa 1: driver | Etapa 2: DSN |
|---|---|---|
| Script | `RedshiftInstall.ps1` | `instalar_dsn.cmd` |
| Contexto | Máquina | Usuário (nunca SYSTEM; grava em `HKCU`) |
| Pré-requisito | MSI do driver no mesmo diretório | Etapa 1 concluída |

## Arquivos que você precisa fornecer

Estes arquivos não são distribuídos no repositório porque contêm dados do seu ambiente:

| Arquivo | Descrição |
|---|---|
| `AmazonRedshiftODBC64-1.6.3.1008.msi` | MSI oficial do driver, na mesma pasta de `RedshiftInstall.ps1`. Se usar outra versão, ajuste `$WapMsiPath` no script. |
| `redshift_dsn.reg` | Configuração do DSN (host, porta, banco, parâmetros de autenticação). |
| `redshift_list.reg` | Registro do DSN na lista de fontes de dados do usuário. |

> Não versione os `.reg` com host, usuário ou credenciais reais. Mantenha-os fora do repositório ou use valores `coloque_seu_host_aqui`.

## Fluxo

1. **`RedshiftInstall.ps1`:** se o driver `Amazon Redshift (x64)` já está instalado, ignora a instalação (sem atualizar nem reparar). Caso contrário instala o MSI silenciosamente e valida o driver ODBC.
2. **`instalar_dsn.cmd`:** confirma que não está como SYSTEM e que o driver existe e importa `redshift_dsn.reg` e `redshift_list.reg` no perfil do usuário.

## Parâmetros

| Script | Parâmetro | Obrigatório | Descrição |
|---|---|---|---|
| `RedshiftInstall.ps1` | `-TelemetryPath` | Não | Diretório (ou UNC) de destino do CSV. Padrão: `C:\Temp\WAP\JsonBackup`. |
| `instalar_dsn.cmd` | n/d | n/d | Sem parâmetros. |

## Uso

```powershell
.\RedshiftInstall.ps1
.\RedshiftInstall.ps1 -TelemetryPath 'coloque_seu_path_aqui'
```

```bat
instalar_dsn.cmd
```

## Logs

- Driver: `C:\Temp\WAP\Logs\WAP_RedshiftInstall.log` e `WAP_RedshiftInstall_MSI.log`
- DSN: `C:\Temp\WAP\Logs\WAP_RedshiftInstall_DSN.log` (usa `%TEMP%\WAP\Logs` se `C:\Temp` não for gravável)
