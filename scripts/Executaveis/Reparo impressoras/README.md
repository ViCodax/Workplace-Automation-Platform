# Reparo de Impressora

Recupera o serviço local de impressão (etapa de máquina) e, em uma etapa separada no perfil do usuário, reconecta a impressora de rede e a define como padrão.

| Item | Etapa 1 (máquina) | Etapa 2 (usuário) |
|---|---|---|
| Script | `WAP-ReparoImpressora.ps1` | `WAP-ReparoImpressora-Usuario.ps1` |
| Contexto | SYSTEM ou administrador | Usuário final |
| Economia estimada | 10 minutos por execução bem-sucedida (fluxo completo) | |

## Fluxo

1. **Etapa de máquina:** valida o driver informado, para o Spooler, limpa a fila pendente, inicia o serviço e aplica `RpcAuthnLevelPrivacyEnabled` no registro.
2. **Etapa de usuário:** após o sucesso da etapa 1, aguarda o Spooler estabilizar, resolve a fila no servidor informado, mapeia a conexão e confirma a impressora padrão no perfil atual.

As conexões e a impressora padrão são por perfil, por isso a etapa 2 deve ser implantada separadamente no contexto do usuário.

## Parâmetros

### `WAP-ReparoImpressora.ps1`

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `-DriverName` | Sim | Nome exato do driver da impressora. |
| `-DriverInfPath` | Sim | Caminho do `.inf` do driver. O pacote do driver deve ser fornecido pelo seu ambiente. Ex.: `coloque_seu_path_aqui`. |
| `-TelemetryPath` | Não | Destino do CSV. Padrão: `C:\Temp\WAP\JsonBackup`. |

### `WAP-ReparoImpressora-Usuario.ps1`

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `-PrinterServer` | Sim | Servidor de impressão. Ex.: `coloque_seu_servidor_aqui`. |
| `-PrinterShare` | Sim | Nome do compartilhamento da impressora. |

## Uso

```powershell
.\WAP-ReparoImpressora.ps1 -DriverName 'NOME EXATO DO DRIVER' -DriverInfPath 'coloque_seu_path_aqui'
.\WAP-ReparoImpressora-Usuario.ps1 -PrinterServer 'coloque_seu_servidor_aqui' -PrinterShare 'NOME_DA_IMPRESSORA'
```

## Logs e telemetria

- Log (compartilhado pelas duas etapas): `C:\Temp\WAP\Logs\WAP_ReparoImpressora.log`
- CSV: gerado pela etapa de máquina (`ReparoImpressora_<COMPUTERNAME>_<yyyyMMddHHmmss>.csv`).

## Limites

- O compartilhamento resolvido pela etapa de usuário pode diferir do nome informado caso a enumeração do servidor encontre outra fila.

Guia institucional: [`wap/Reparo-Impressora.md`](../../../wap/Reparo-Impressora.md)
