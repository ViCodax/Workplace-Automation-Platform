# Instalador DBeaver

## Objetivo

Instalar a versao empacotada do DBeaver e aplicar o workspace corporativo com configuracoes e drivers incluidos no pacote.

## O que faz

- Valida previamente o instalador, arquivos essenciais do workspace e drivers JAR.
- Encerra DBeaver e processos Java, tenta desinstalar uma instalacao existente e executa o instalador silencioso para todos os usuarios.
- Quando resolve com seguranca o perfil-alvo, remove `DBeaverData` anterior e copia drivers e configuracoes do workspace.
- Valida arquivos-chave e registra o resultado.

## Atencao antes da execucao

A rotina e de reinstalacao, nao apenas reparo: ela remove a pasta `DBeaverData` anterior do perfil-alvo antes de aplicar o workspace do pacote. Configuracoes locais nao incluidas no pacote podem ser perdidas. Como a aplicacao e instalada antes da injecao do workspace, uma falha posterior pode deixar a instalacao concluida sem workspace atualizado.

Implementacao e payload: `scripts/Instaladores/Dbeaver/`. Log em `C:\Temp\WAP\Logs\WAP_DBeaverInstall.log`; telemetria CSV central com fallback local. Estimativa de economia: 25 minutos.
