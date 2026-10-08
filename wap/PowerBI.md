# Telemetria WAP no Power BI

## Fonte atual

Os scripts PowerShell WAP exportam CSV para o diretório informado em `-TelemetryPath`; sem o parâmetro, ou quando a rede nao esta disponivel, a maioria usa `C:\Temp\WAP\JsonBackup` (WSL/Docker tem caminhos locais proprios, descritos nos guias tecnicos). O CMD do Docker grava log, mas nao exporta CSV. Portanto, nao filtre a pasta por JSON.

Cada arquivo costuma representar uma execucao e usa nome com ferramenta, computador e data. Os campos comuns incluem `Data`, `Ferramenta`, `Departamento`, `Status`, `DuracaoSegundos`, `Erro` e `TempoEconomizadoMins`; alguns scripts tambem exportam `AcessoRede` ou `UptimeHoras`. Os esquemas nao sao identicos em todos os pacotes.

## Importar a pasta

No Power BI Desktop, use **Obter dados > Pasta**, informe o diretório central de telemetria (`coloque_seu_path_aqui`) e combine os arquivos `.csv`. Confira a etapa de combinacao para manter colunas opcionais ausentes como nulas, em vez de descartar arquivos de esquemas diferentes. Defina `Data` como data/hora e `DuracaoSegundos`, `TempoEconomizadoMins` e `UptimeHoras` como numericos.

Consulta M minima para inventariar os arquivos CSV:

```m
let
    Source = Folder.Files("coloque_seu_path_aqui"),
    CsvFiles = Table.SelectRows(Source, each Text.Lower([Extension]) = ".csv"),
    Parsed = Table.AddColumn(CsvFiles, "Rows", each
        Csv.Document([Content], [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv])
    )
in
    Parsed
```

Ao combinar, promova a primeira linha de cada arquivo como cabecalho e expanda as tabelas. Evite assumir que todas as colunas listadas em um unico esquema existem em cada CSV.

## Indicadores sugeridos

```DAX
TotalExecucoes = COUNTROWS(Dados)
ExecucoesComSucesso = CALCULATE(COUNTROWS(Dados), Dados[Status] = "Sucesso")
TaxaSucesso = DIVIDE([ExecucoesComSucesso], [TotalExecucoes])
Falhas = CALCULATE(COUNTROWS(Dados), Dados[Status] = "Falha")
TempoEstimadoEconomizadoHoras = DIVIDE(
    SUMX(FILTER(Dados, Dados[Status] = "Sucesso"), Dados[TempoEconomizadoMins]),
    60
)
DuracaoMediaSegundos = AVERAGE(Dados[DuracaoSegundos])
```

Trate `TempoEconomizadoMins` como estimativa fixa de ROI registrada pelo script, nao como medicao observada do tempo poupado. Filtre falhas e sucessos explicitamente ao calcular economia. Use `Ferramenta`, `Departamento`, `Data` e `Status` para segmentar os indicadores.

## Observacoes de qualidade

- Os nomes e colunas variam entre ferramentas; preserve os dados originais ao combinar.
- Uma pasta local de fallback nao e enviada automaticamente para a rede. Sua incorporacao exige processo operacional separado.
- A telemetria do instalador Docker PowerShell e diferente da entrada CMD, que registra somente log.
- O dashboard HTML em `Misc/` e um material historico e nao consome automaticamente os CSVs atuais.
