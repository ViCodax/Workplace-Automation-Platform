# Reparo Avançado do Windows

Executa uma sequência de manutenção e reparo do Windows, registrando resultado operacional e telemetria.

| Item | Valor |
|---|---|
| Script | `WAP-ReparoAvançado.ps1` |
| Contexto | Máquina |
| Privilégios | Administrador |
| Reinicialização | Não é solicitada pelo script |
| Economia estimada | 40 minutos por execução bem-sucedida |

## O que faz

- Coleta IPv4, espaço livre no disco C: e tempo desde a última inicialização (registrados no log).
- Executa SFC e DISM para verificar e reparar componentes do Windows.
- Executa CHKDSK em modo de verificação online e tenta otimizar o volume C:.
- Para Windows Update e BITS, remove `SoftwareDistribution` e tenta iniciar os serviços novamente.

## Parâmetros

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `-TelemetryPath` | Não | Diretório (ou UNC) de destino do CSV. Padrão: `C:\Temp\WAP\JsonBackup`. Use `coloque_seu_path_aqui` como referência para o seu ambiente. |

## Uso

```powershell
.\WAP-ReparoAvançado.ps1
.\WAP-ReparoAvançado.ps1 -TelemetryPath 'coloque_seu_path_aqui'
```

## Logs e telemetria

- Log: `C:\Temp\WAP\Logs\WAP_ReparoAvancado.log`
- CSV: `ReparoAvancado_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.csv`, com fallback local em `C:\Temp\WAP\JsonBackup`.

## Limites

- É uma rotina de manutenção, não garante que todos os reparos individuais foram concluídos: vários comandos são isolados em blocos de tratamento de erro e o código final representa o resultado geral.
- A execução completa pode ser demorada (SFC, DISM e CHKDSK).

Guia institucional: [`wap/Reparo-Avancado.md`](../../../wap/Reparo-Avancado.md)
