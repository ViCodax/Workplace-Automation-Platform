# Padrao Oficial para Novos Scripts WAP

Este documento define a base de engenharia para **novos scripts PowerShell WAP**. Ele nao autoriza alterar nem substituir os scripts ja distribuidos em `scripts/`. Qualquer migracao desses scripts exige pedido, homologacao funcional e aprovacao separados.

O repositorio nao distribui template de script nem de log; siga o contrato e o formato descritos neste documento.

## Formato dos logs

- Cada execucao deve formar um bloco com separadores `==========================================`, titulo da ferramenta e dados de inicio, identidade, usuario-alvo, computador e departamento.
- Registrar datas de inicio e fim em `yyyy-MM-dd HH:mm:ss`. Cada campo e cada mensagem devem ocupar sua propria linha, sem agrupar dados com `|`.
- Manter mensagens da operacao em linhas consecutivas. Usar linhas em branco apenas entre os blocos de cabecalho, operacao, resumo, telemetria e entre execucoes, conforme o modelo.
- Mensagens informativas nao recebem prefixo de timestamp ou `[INFO]`. Avisos usam `AVISO:` e falhas usam `ERRO:`; detalhes e categoria do erro ficam em linhas separadas quando aplicavel.
- O resumo deve conter `Fim`, `Duracao` em segundos e `Status`. A telemetria vem depois do resumo e registra destino, resultado e eventual fallback sem mudar o resultado operacional.
- Gravar em UTF-8 com quebras de linha Windows (CRLF), sem misturar codificacoes no mesmo arquivo. Preservar o historico e nao registrar senhas, tokens ou segredos.
- Substituir os campos entre `<...>` pelos valores reais. Incluir apenas mensagens e resultados que realmente ocorreram; nao registrar verificacoes ficticias nem acrescentar linhas vazias entre todos os eventos.

## 1. Resultado do pente-fino

A auditoria dos arquivos em `scripts/` encontrou um nucleo recorrente, mas nao um contrato consistente entre todos eles:

| Area observada | Evidencia nos scripts atuais | Regra para novos scripts |
| --- | --- | --- |
| Log | Reparos e varios instaladores registram execucao; diretorio comum e `C:\Temp\WAP\Logs`, mas Docker PowerShell usa `%LOCALAPPDATA%` e ha mais de uma implementacao | Script autonomo Windows registra inicio, eventos relevantes, falhas e encerramento em `C:\Temp\WAP\Logs`; wrappers delegam o log a ferramenta chamada ou registram apenas a invocacao |
| Telemetria | Muitos scripts exportam CSV para um compartilhamento central configurável; ha fallback local, layouts locais diferentes e nomes de arquivo que podem sobrescrever execucoes | Padronizar o esquema abaixo, nome unico por execucao e fallback local. Falha de rede nao deve apagar o resultado local nem converter sucesso operacional em falha |
| Usuario e departamento | Os reparos repetem deteccao de usuario e consulta AD; instaladores por usuario e scripts SYSTEM tem contextos diferentes | Identidade do processo e usuario-alvo sao conceitos distintos. Registrar `Unknown` quando nao puder determinar; consultar AD e enriquecer departamento apenas como dado opcional |
| Erros | `CategoriaErro` e classificada em varios scripts, mas em geral nao faz parte do CSV; categorias e mensagens variam | Incluir erro e categoria normalizados na telemetria. Nunca tratar uma heuristica de texto como substituta da captura do erro original |
| Retry | Ha repeticao tanto para a operacao quanto para entrega do CSV, sem semantica uniforme | Contar tentativas da operacao separadamente das tentativas de telemetria; documentar limite, espera e motivo de cada retry |
| Resultado e codigo de saida | Predominam `0`/`1`; WSL usa `3010` para reinicio e DBeaver tem `SucessoParcial` com codigo `0` | O codigo de saida representa o resultado contratado com SCCM. Usar `0` sucesso, `1` falha e `3010` somente quando reinicio for requerido e o deployment estiver configurado para interpreta-lo |
| Verificacao | Alguns reparos podem concluir sem validar o resultado de cada comando nativo | Toda acao obrigatoria deve verificar o resultado por excecao, `$LASTEXITCODE`, estado final ou uma combinacao adequada |
| Contexto de execucao | Existem scripts SYSTEM/dispositivo, scripts de usuario, duas etapas e wrappers | Declarar o contexto e o usuario-alvo esperado antes de escolher identidade, perfil, caminhos e forma de elevacao |

### Arquivos que nao devem ser forcados no template

- `DockerInstall.cmd` e outros pontos de entrada CMD: manter como wrappers; nao duplicar neles o motor de telemetria PowerShell.
- `DockerInstall-Usuario.ps1`, `DockerFase2-Usuario.ps1` e outros auxiliares de execucao por usuario: manter a fronteira SYSTEM/usuario explicita. Reutilizar o contrato de log/resultado quando fizer sentido, sem fingir que o usuario do processo e o alvo quando a etapa roda como SYSTEM.
- `WSLInstall.ps1`: perfil de instalacao de dispositivo, com tratamento especifico de reboot/`3010`, componentes do Windows, distribuicao e idempotencia. Adotar os campos comuns, mas conservar seu contrato operacional homologado.
- `firstrun-user.sh` e `provision-docker.sh`: scripts Linux Bash; devem ter padrao Bash proprio se necessario, sem incorporar sintaxe ou helpers PowerShell.
- Scripts de etapa ou utilitarios sem resultado independente: nao gerar uma segunda linha de telemetria se isso duplicar a execucao ja medida pelo orquestrador. Registrar eventos no log do fluxo principal.

## 2. Contrato de um novo script autonomo

### Obrigatorio

1. **Proposito, contexto e pre-requisitos**: ferramenta, versao, categoria, contexto SCCM (SYSTEM ou usuario), arquitetura exigida, dependencias e se ha reinicio.
2. **Idempotencia**: verificar o estado antes de alterar; uma segunda execucao deve manter o estado correto e nao degradar a maquina.
3. **Log local**: criar o diretorio se necessario e seguir o formato descrito na secao "Formato dos logs", com datas no cabecalho/resumo, mensagens em linhas separadas e prefixos `AVISO:` e `ERRO:` quando aplicaveis; nunca registrar senha, token, segredo ou dados pessoais desnecessarios.
4. **Tratamento de falha**: usar erros terminantes para comandos PowerShell criticos; verificar `$LASTEXITCODE` imediatamente apos executaveis nativos; preservar mensagem original e classificar a falha.
5. **Verificacao de resultado**: checar o estado final esperado, nao apenas se o comando de instalacao/reparo foi iniciado.
6. **Resultado SCCM**: sair explicitamente com o codigo contratado. `0` = operacao concluida, `1` = falha operacional, `3010` = operacao concluida e reinicio requerido quando isso fizer parte do deployment. Nao usar `3010` como codigo generico de sucesso.
7. **Telemetria CSV**: uma linha por execucao independente, esquema estavel e nome de arquivo que nao colida com outra execucao.
8. **Fallback**: se o destino central estiver indisponivel, tentar gravar localmente e manter o log local. A indisponibilidade da telemetria, por si so, nao altera o codigo da operacao.
9. **Saidas controladas**: evitar depender de prompts, janelas ou estado de uma sessao interativa em execucao SCCM nao interativa.

### Condicional ao contexto

- Detectar e relancar em PowerShell 64-bit quando o script usar componentes que exigem essa arquitetura. O relancamento precisa preservar argumentos, identidade, codigo de retorno e evitar loop.
- Resolver usuario-alvo e perfil somente quando a operacao atuar sobre o perfil do usuario. Em SYSTEM, nao preencher o usuario-alvo com `SYSTEM`; usar o usuario interativo validado ou `Unknown`.
- Consultar Active Directory somente como enriquecimento opcional. Falha de rede/modulo/permissao nao deve impedir a operacao principal.
- Usar `3010` somente quando houver reinicio efetivamente necessario e o retorno do deployment for interpretado corretamente pelo SCCM.
- Fazer retry somente para falhas transitorias conhecidas, com limite e espera definidos. Nao repetir indefinidamente uma acao que possa causar efeitos cumulativos.

## 3. Esquema oficial de telemetria

Colunas padrao, nesta ordem:

| Coluna | Regra |
| --- | --- |
| `Data` | Inicio da execucao em `yyyy-MM-dd HH:mm:ss` |
| `Ferramenta` | Identificador estavel, sem incluir dados do usuario |
| `VersaoScript` | Versao do script/pacote executado |
| `Categoria` | Uma das categorias mantidas no catalogo WAP, por exemplo `Reparo` ou `Instalador` |
| `Usuario` | Usuario-alvo validado; `Unknown` se nao aplicavel ou nao identificado |
| `Computador` | Nome do dispositivo |
| `Departamento` | Atributo AD, quando disponivel; senao `Unknown` |
| `Status` | `Sucesso`, `SucessoParcial`, `Falha` ou `ReinicioNecessario` |
| `DuracaoSegundos` | Duracao total da operacao em segundos, arredondada a duas casas |
| `TempoEconomizadoMins` | Estimativa aprovada para a ferramenta; zero se nao houver metodo defensavel |
| `Erro` | Mensagem segura e resumida; vazio quando nao houve falha |
| `CategoriaErro` | `Nenhum`, `PermissaoDenegada`, `CaminhoNaoEncontrado`, `Timeout`, `DependenciaAusente`, `Rede` ou `Outro` |
| `TentativasRetry` | Tentativas adicionais da operacao, sem contar tentativas de exportacao CSV |

`SucessoParcial` precisa ter criterio objetivo no proprio script. `ReinicioNecessario` deve corresponder ao codigo `3010` apenas quando aplicavel. Se operacao falhar, preencher `Status=Falha`, `Erro`, `CategoriaErro` e codigo `1`. Se a operacao terminar normalmente, erro vazio e categoria `Nenhum`.

### Destino e nome do CSV

- Destino central de telemetria: informado por `-TelemetryPath` (compartilhamento UNC gravavel pela conta de execucao). Sem o parametro, o script grava apenas no fallback local.
- Fallback local padrao: `C:\Temp\WAP\JsonBackup`. O diretorio mantem o nome historico, embora o formato de exportacao seja CSV; scripts novos devem usar o nome existente para compatibilidade operacional.
- Nome sugerido: `<Ferramenta>_<Computador>_<yyyyMMdd_HHmmss_fff>.csv`.
- Criar um arquivo por execucao evita colisao entre execucoes simultaneas e sobrescrita acidental. Nao trocar para agregacao em arquivo compartilhado sem definir concorrencia, retencao e compatibilidade com consumidores Power BI.
- A telemetria deve usar as colunas na mesma ordem e sem renomear `Data`, `Ferramenta` ou `CategoriaErro` por conveniencia local.
- O log pode indicar falha de exportacao; ela nao e uma falha operacional e nao muda o status/codigo SCCM da acao.

## 4. Falhas e processos nativos

PowerShell pode continuar apos erros nao terminantes, e executaveis nativos nem sempre lancam excecao. Para cada dependencia critica:

- Use `-ErrorAction Stop` quando o cmdlet oferecer essa opcao.
- Capture a excecao no limite da operacao, registre-a e converta-a para o contrato de status/codigo.
- Leia `$LASTEXITCODE` logo apos cada processo nativo e valide o codigo permitido.
- Verifique o estado final quando o processo retornar sucesso; exemplos: servico no estado esperado, pacote instalado, conexao reparada ou comando disponivel.
- Mantenha falhas opcionais como aviso apenas quando a funcao for realmente opcional e a operacao principal puder ser considerada concluida.
- Diferencie retry operacional de retry da escrita CSV; nao exporte a contagem de um como se fosse a do outro.

## 5. Identidade, arquitetura e instalacao

- `GetCurrent()` identifica a identidade do processo. Nao a confundir com o usuario cujo perfil ou sessao sera alterado.
- Em SYSTEM, caminhos de perfil nao devem derivar de `$env:USERPROFILE` esperando que seja o usuario interativo.
- Operacao de usuario deve declarar como encontra e valida a sessao/usuario-alvo, como executa sob essa identidade e como transmite resultado e logs para o orquestrador.
- A verificacao de arquitetura 64-bit e um requisito da ferramenta/dependencia, nao uma linha obrigatoria em todo script.
- Comandos de instalacao devem ser silenciosos e adequados ao SCCM; argumentos e codigos de retorno do instalador precisam ser conferidos na documentacao do fornecedor.

## 6. Roteiro de revisao antes de distribuir

1. Confirmar proprietario, escopo, contexto SCCM, pre-requisitos e retorno esperado.
2. Rever idempotencia e efeitos colaterais em uma maquina limpa e em uma maquina que ja esteja configurada.
3. Testar sucesso, falha operacional, dependencia ausente, destino de rede indisponivel e, se aplicavel, necessidade de reinicio.
4. Conferir log, uma linha CSV, fallback local, campos e codigo de saida em cada caminho.
5. Confirmar que retries sao limitados e que a telemetria nao e contada como tentativa da operacao.
6. Homologar o pacote e o comportamento pelo metodo de distribuicao SCCM antes de publicar.

Este padrao e uma base para novos scripts, nao um contrato retroativo. Os dados historicos podem ter nomes, colunas, caminhos e codigos diferentes; consumidores existentes devem ser migrados separadamente e com compatibilidade planejada.
