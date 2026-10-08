# Reparo avancado do Windows

## Objetivo

Executar uma sequencia de manutencao e reparo do Windows, registrando resultado operacional e telemetria WAP.

## O que faz

- Coleta endereco IPv4, espaco livre no disco C: e tempo desde a ultima inicializacao para troubleshooting; esses dados sao registrados no log.
- Executa SFC e DISM para verificar e reparar componentes do Windows.
- Executa CHKDSK em modo de verificacao online e tenta otimizar o volume C:.
- Para os servicos Windows Update e BITS, remove `SoftwareDistribution` e tenta iniciar os servicos novamente.
- Registra log em `C:\Temp\WAP\Logs\WAP_ReparoAvancado.log` e exporta CSV para a pasta central de telemetria, com fallback local.

## Execucao e limites

Implementacao: `scripts/Executaveis/Reparo avancado/WAP-ReparoAvançado.ps1`. E uma rotina de manutencao do sistema, nao uma garantia de que todos os reparos individuais foram concluídos; varios comandos sao isolados em blocos de tratamento de erro e o codigo final representa o resultado geral do script.

Estimativa de economia usada na telemetria: 40 minutos por execucao bem-sucedida. E uma estimativa de ROI, nao uma medicao de tempo real poupado.
