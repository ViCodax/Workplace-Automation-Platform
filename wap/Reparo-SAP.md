# Reparo SAP

## Objetivo

Restaurar os arquivos de landscape do SAP Logon a partir da origem corporativa.

## O que faz

- Localiza o usuario Windows detectado pelo script e usa seu perfil em `C:\Users\<usuario>\AppData\Roaming\SAP\Common`.
- Cria a pasta de destino quando necessario.
- Faz copia de seguranca dos XML existentes com extensao `.bkp`.
- Copia `SAPUILandscape.xml` e `SAPUILandscapeGlobal.xml` de `-SapSourcePath` (`coloque_seu_path_aqui`).

## Execucao e limites

Implementacao: `scripts/Executaveis/Reparo SAP/WAP-ReparoSAP.ps1`. O script depende de acesso de leitura a origem de rede e de um usuario/perfil Windows valido. Ele substitui os arquivos-alvo; as copias `.bkp` preservam a versao anterior.

Log: `C:\Temp\WAP\Logs\WAP_ListaSAP.log`. Telemetria CSV central com fallback local. Estimativa de economia: 5 minutos por execucao bem-sucedida.
