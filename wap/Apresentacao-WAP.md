# WAP | Workplace Automation Platform
## Apresentacao institucional

### 1. Contexto

A equipe de Workplace atende demandas recorrentes que consomem tempo de usuarios e analistas, mesmo quando seguem procedimentos conhecidos. Variacoes manuais, dependencias de contexto e etapas repetitivas tornam essas tarefas mais lentas e sujeitas a retrabalho.

### 2. Proposito

O WAP organiza automacoes de suporte e instalacao em uma experiencia self-service distribuida pelo SCCM. O objetivo e tornar procedimentos repetiveis mais consistentes, reduzir intervencoes manuais e liberar a equipe para demandas que exigem diagnostico especializado.

### 3. Principios

- **Padronizacao:** executar procedimentos aprovados de forma repetivel.
- **Contexto correto:** separar operacoes de maquina, que podem rodar como SYSTEM, das que precisam do perfil do usuario.
- **Seguranca operacional:** validar pre-requisitos, preservar dados quando aplicavel e falhar sem mascarar estados incompletos.
- **Observabilidade:** manter logs locais e telemetria estruturada, respeitando as limitacoes de rede e de contexto do SCCM.
- **Evolucao controlada:** documentar comportamento real e homologar mudancas antes de distribuir.

### 4. Modelo de operacao

As automacoes sao empacotadas por responsabilidade para que o SCCM distribua somente o conteudo necessario. Os codigos de retorno comunicam sucesso, falha ou reinicializacao requerida. Os logs apoiam troubleshooting; arquivos CSV consolidam uso, status, duracao e estimativas de tempo economizado.

O WAP nao substitui o suporte especializado. Quando uma automacao nao consegue confirmar o resultado ou encontra uma condicao fora do escopo, o caso continua exigindo avaliacao tecnica.

### 5. Governanca da informacao

Os arquivos em `scripts/` sao a referencia do comportamento distribuido. O `README.md` de cada pasta de script e os guias desta pasta explicam cada ferramenta de forma independente. Este documento apresenta o projeto e nao descreve o funcionamento de ferramentas individuais. Auditorias antigas, prototipos e backups permanecem identificados como historico, sem definir o estado atual.

### 6. Indicadores de valor

A telemetria permite acompanhar volume de execucoes, taxa de sucesso, duracao e distribuicao de falhas. `TempoEconomizadoMins` e uma estimativa fixa de referencia para calculo de ROI, nao uma medicao direta do tempo poupado em cada caso. O [guia Power BI](PowerBI.md) descreve o formato de dados e as metricas.

### 7. Evolucao

A evolucao do WAP deve priorizar confiabilidade, clareza de ownership, consistencia entre implementacao e documentacao, e validacao da experiencia de distribuicao pelo SCCM. Novas integracoes e automacoes devem ser tratadas como etapas futuras, com escopo, responsaveis e criterios de homologacao definidos antes de serem apresentadas como entregues.
