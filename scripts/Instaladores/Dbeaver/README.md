# Instalador DBeaver

Instala a versão empacotada do DBeaver e aplica um workspace padronizado (configurações e drivers).

| Item | Valor |
|---|---|
| Script | `WAP-DBeaver-Install.ps1` |
| Contexto | Máquina, com resolução do perfil-alvo |
| Privilégios | Administrador |
| Economia estimada | 25 minutos por instalação bem-sucedida |

> **Atenção:** a rotina é de **reinstalação**. Ela remove a pasta `DBeaverData` anterior do perfil-alvo antes de aplicar o workspace do pacote; configurações locais que não estejam no pacote podem ser perdidas. Como a aplicação é instalada antes da injeção do workspace, uma falha posterior pode deixar a instalação concluída sem o workspace atualizado.

## O que faz

1. Valida previamente o instalador, os arquivos essenciais do workspace e os drivers JAR.
2. Encerra DBeaver e processos Java, tenta desinstalar uma instalação existente e executa o instalador silencioso para todos os usuários.
3. Quando resolve com segurança o perfil-alvo, remove o `DBeaverData` anterior e copia drivers e configurações.
4. Valida os arquivos-chave e registra o resultado.

## Parâmetros

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `-WorkspaceSourcePath` | Sim | Pasta com `drivers` e `workspace6`. Ex.: `coloque_seu_path_aqui`. |
| `-DBeaverInstallerPath` | Quando o DBeaver ainda não está instalado | Executável do instalador do DBeaver. Ex.: `coloque_seu_path_aqui`. |
| `-TelemetryPath` | Não | Destino do CSV. Padrão: `C:\Temp\WAP\JsonBackup`. |

## Uso

```powershell
.\WAP-DBeaver-Install.ps1 -WorkspaceSourcePath 'coloque_seu_path_aqui' -DBeaverInstallerPath 'coloque_seu_path_aqui'
```

## Logs e telemetria

- Log: `C:\Temp\WAP\Logs\WAP_DBeaverInstall.log`
- CSV: `DBeaverInstall_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.csv`, com fallback local em `C:\Temp\WAP\JsonBackup`.

Guia institucional: [`wap/Instalador-DBeaver.md`](../../../wap/Instalador-DBeaver.md)
