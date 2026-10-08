# Reparo SAP

Restaura os arquivos de landscape do SAP Logon a partir de uma origem configurável.

| Item | Valor |
|---|---|
| Script | `WAP-ReparoSAP.ps1` |
| Contexto | Usuário detectado pelo script |
| Privilégios | Acesso de leitura à origem e escrita no perfil do usuário |
| Reinicialização | Não |
| Economia estimada | 5 minutos por execução bem-sucedida |

## O que faz

1. Localiza o usuário Windows detectado e usa o perfil em `C:\Users\<usuario>\AppData\Roaming\SAP\Common`.
2. Cria a pasta de destino quando necessário.
3. Faz cópia de segurança dos XML existentes com extensão `.bkp`.
4. Copia `SAPUILandscape.xml` e `SAPUILandscapeGlobal.xml` da origem informada.

## Parâmetros

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `-SapSourcePath` | Sim | Pasta que contém `SAPUILandscape.xml` e `SAPUILandscapeGlobal.xml`. Ex.: `coloque_seu_path_aqui`. |
| `-TelemetryPath` | Não | Diretório (ou UNC) de destino do CSV. Padrão: `C:\Temp\WAP\JsonBackup`. |

## Uso

```powershell
.\WAP-ReparoSAP.ps1 -SapSourcePath 'coloque_seu_path_aqui'
```

## Logs e telemetria

- Log: `C:\Temp\WAP\Logs\WAP_ListaSAP.log`
- CSV: `ListaSAP_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.csv`, com fallback local em `C:\Temp\WAP\JsonBackup`.

## Limites

- Substitui os arquivos de destino; as cópias `.bkp` preservam a versão anterior.
- Depende de acesso de leitura à origem e de um usuário/perfil Windows válido.

Guia institucional: [`wap/Reparo-SAP.md`](../../../wap/Reparo-SAP.md)
