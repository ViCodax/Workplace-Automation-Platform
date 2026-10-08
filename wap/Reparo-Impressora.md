# Reparo de impressora

## Objetivo

Recuperar o servico local de impressao e, em uma etapa separada no perfil do usuario, reconectar a impressora de rede e defini-la como padrao.

## Fluxo

1. `WAP-ReparoImpressora.ps1` para o Spooler, limpa os arquivos pendentes da fila, inicia o servico e aplica `RpcAuthnLevelPrivacyEnabled` no registro.
2. Apos sucesso da etapa administrativa, `WAP-ReparoImpressora-Usuario.ps1` aguarda o Spooler estabilizar, resolve a fila disponível no servidor de impressão informado em `-PrinterServer`, tenta mapear a conexao e confirma a impressora padrao no perfil atual.
3. A etapa de usuario deve ser implantada separadamente no contexto do usuario, conforme a dependencia/configuracao SCCM adotada.

## Contexto e evidencias

A etapa administrativa e executada como SYSTEM/administrador; a etapa de conexao deve executar como usuario, pois conexoes e impressora padrao sao por perfil. Ambas acrescentam eventos ao log `C:\Temp\WAP\Logs\WAP_ReparoImpressora.log`; a telemetria CSV e produzida pela etapa administrativa. O CMD que esta ao lado dos scripts e um comando legado separado: fixa outra fila (`KONICA MINOLTA Universal PCL`) e nao chama o script PowerShell. Nao o trate como equivalente a etapa de usuario sem confirmar o comando realmente publicado no SCCM.

Implementacao: `scripts/Executaveis/Reparo impressoras/`. A pasta atual nao contem pacote de driver INF, e o script administrativo atual nao instala driver. O compartilhamento resolvido pelo script de usuario pode diferir do nome preferido caso a enumeracao do servidor encontre outra fila.

Estimativa WAP: 10 minutos por execucao bem-sucedida.
