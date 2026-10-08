# ⚙️ Workplace Automation Platform (WAP)
### Toolkit de automação em PowerShell para suporte Workplace, troubleshooting e redução de intervenções manuais.

## 📑 Sumário
- [Sobre](#sobre)
- [Objetivos](#objetivos)
- [Ferramentas disponíveis](#ferramentas)
- [Estrutura do repositório](#estrutura)
- [Requisitos](#requisitos)
- [Como usar](#como-usar)
- [Distribuição via SCCM](#sccm)
- [Telemetria](#telemetria)
- [Roadmap](#roadmap)
- [Contribuição](#contribuicao)
- [Licença](#licenca)
- [Autor](#autor)

<a id="sobre"></a>
## 📌 Sobre

A **Workplace Automation Platform (WAP)** é uma iniciativa de automação focada na melhoria de processos técnicos e repetitivos de suporte, construída em **PowerShell** e pensada para tecnologias de distribuição corporativa.

As ferramentas foram desenvolvidas como parte da plataforma de automação do time de Workplace, distribuída em modelo **self-service** pelo SCCM. Este repositório é a versão **pública** do projeto: os scripts (`scripts/`) não têm caminhos de rede, servidores, IPs, DNS ou destinos de telemetria preconfigurados, e a documentação das ferramentas fica em `wap/`. Todo valor dependente do ambiente aparece como `coloque_seu_path_aqui` e deve ser substituído antes do uso.

O WAP reúne **11 ferramentas**: 5 rotinas de reparo e 6 instaladores (o ambiente Docker é composto por dois pacotes independentes, WSL e Docker). A distribuição é centralizada via **Microsoft Configuration Manager (SCCM)**, com logs padronizados e telemetria CSV por execução.

> O WAP não substitui o suporte especializado: quando uma automação não consegue confirmar o resultado ou encontra uma condição fora do escopo, o caso continua exigindo avaliação técnica.

<a id="objetivos"></a>
## 🎯 Objetivos

A plataforma foi criada para solucionar cenários recorrentes de suporte que tradicionalmente exigem intervenção manual.

| Objetivo | Descrição |
|---|---|
| 🔁 Reduzir tarefas repetitivas | Elimina a execução manual de procedimentos técnicos recorrentes |
| ⏱️ Diminuir tempo de troubleshooting | Automatiza diagnósticos e reparos que levariam minutos/horas manualmente |
| 📏 Padronizar procedimentos | Garante que todo suporte siga o mesmo fluxo de resolução |
| 📈 Melhorar escalabilidade operacional | Permite atender mais usuários sem aumentar o time proporcionalmente |
| 🚀 Aumentar produtividade da equipe | Libera o time de Workplace para tarefas de maior valor |
| 🧪 Disponibilizar rotinas consistentes | Diagnóstico e reparo padronizados, testados e documentados |
| 📦 Permitir distribuição via SCCM | Implantação centralizada em toda a base corporativa |
| 🛠️ Automatizar instalações | Softwares instalados e configurados sem intervenção do analista |
| 📊 Coletar dados de execução | Logs estruturados para análise operacional e telemetria |

<a id="ferramentas"></a>
## 🛠️ Ferramentas disponíveis

Guia técnico de cada ferramenta no `README.md` da sua pasta em [`scripts/`](scripts/README.md) e, em versão institucional, em [`wap/`](wap/README.md). A economia de tempo indicada é uma **estimativa fixa de referência para ROI**, não uma medição do tempo real poupado.

🔵 **Reparos** · 🟢 **Instaladores**

### 🔵 Reparos

| Ferramenta | Contexto | O que faz | Economia est. | Documentação |
|---|---|---|---|---|
| Reparo do Teams | Usuário | Encerra processos do Teams e do WebView2, remove o cache do novo Teams (com retry) e solicita a reabertura pelos protocolos `msteams:`, `ms-teams:` e `teams:` | 5 min | [Uso](scripts/Executaveis/Reparo%20Teams/README.md) · [Visão geral](wap/Reparo-Teams.md) |
| Reparo Rápido do Windows | Máquina | Limpa DNS, solicita reset de Winsock/TCP-IP, limpa TEMP, limpa o cache do Teams e reinicia o Explorer. O reset de rede pode exigir reinicialização | 20 min | [Uso](scripts/Executaveis/Reparo%20Rapido/README.md) · [Visão geral](wap/Reparo-Rapido.md) |
| Reparo Avançado do Windows | Máquina | Executa SFC, DISM, CHKDSK (verificação online) e otimização do C:, e reinicia os serviços do Windows Update/BITS limpando `SoftwareDistribution` | 40 min | [Uso](scripts/Executaveis/Reparo%20avancado/README.md) · [Visão geral](wap/Reparo-Avancado.md) |
| Reparo SAP | Usuário | Faz backup (`.bkp`) e restaura `SAPUILandscape.xml` e `SAPUILandscapeGlobal.xml` a partir da origem configurada | 5 min | [Uso](scripts/Executaveis/Reparo%20SAP/README.md) · [Visão geral](wap/Reparo-SAP.md) |
| Reparo de Impressora | Máquina + usuário | **Etapa 1 (admin/SYSTEM):** para o Spooler, limpa a fila, reinicia o serviço e aplica `RpcAuthnLevelPrivacyEnabled`. **Etapa 2 (usuário):** reconecta a fila de rede e confirma a impressora padrão | 10 min | [Uso](scripts/Executaveis/Reparo%20impressoras/README.md) · [Visão geral](wap/Reparo-Impressora.md) |

### 🟢 Instaladores

| Ferramenta | Contexto | O que faz | Economia est. | Documentação |
|---|---|---|---|---|
| Runtime WSL | SYSTEM | Habilita os recursos `Microsoft-Windows-Subsystem-Linux` e `VirtualMachinePlatform` e instala o runtime WSL via MSI. Retorna `3010` quando exige reinicialização. Não importa distro nem instala Docker | 30 min | [Uso](scripts/Instaladores/WSL/README.md) · [Visão geral](wap/Instalador-WSL.md) |
| Docker CE em WSL | Usuário | Importa uma distro Ubuntu a partir de imagem corporativa com Docker CE, Compose e systemd já incluídos, valida o daemon e instala o *first-run*. **Não usa Docker Desktop.** Independente do instalador WSL, que é pré-requisito | 20 min | [Uso](scripts/Instaladores/Docker/README.md) · [Visão geral](wap/Instalador-Docker.md) |
| DBeaver | Máquina | Instala o DBeaver empacotado e aplica o workspace corporativo (drivers e configurações). **Atenção:** é uma reinstalação e remove o `DBeaverData` anterior do perfil-alvo | 25 min | [Uso](scripts/Instaladores/Dbeaver/README.md) · [Visão geral](wap/Instalador-DBeaver.md) |
| Git Bash | Usuário | Instala o Git for Windows via WinGet, com fallback para o instalador oficial, e valida `git --version` | 5 min | [Uso](scripts/Instaladores/Gitbash/README.md) · [Visão geral](wap/Instalador-GitBash.md) |
| Claude CLI | Usuário | Instala o Claude Code CLI (WinGet em tarefa agendada, WinGet no processo ou instalador oficial) e valida `claude --version` | 10 min | [Uso](scripts/Instaladores/ClaudeCLI/README.md) · [Visão geral](wap/Instalador-Claude-CLI.md) |
| Amazon Redshift ODBC | Máquina + usuário | Instala o driver ODBC (MSI) e, em etapa de usuário, importa o DSN e a lista de fontes de dados a partir de arquivos `.reg` fornecidos pelo seu ambiente | n/d | [Uso](scripts/Instaladores/ODBC/README.md) |

### Limites conhecidos

- Os reparos fazem o melhor esforço para itens bloqueados e nem sempre confirmam o resultado de cada comando externo.
- O Reparo do Teams não valida que a interface do Teams realmente abriu.
- O script de impressora administrativo não instala drivers; a etapa de usuário deve ser implantada separadamente no contexto do usuário.
- Em Git Bash e Claude CLI, a instalação depende de internet, WinGet e, no caso do Claude CLI, de uma sessão de usuário ativa.

<a id="estrutura"></a>
## 📂 Estrutura do repositório

```
Workplace-Automation-Platform/
├── scripts/                          # Scripts por ferramenta, cada pasta com seu README.md
│   ├── README.md                     # Índice das ferramentas
│   ├── Executaveis/                  # Reparos
│   │   ├── Reparo avancado/
│   │   ├── Reparo impressoras/
│   │   ├── Reparo Rapido/
│   │   ├── Reparo SAP/
│   │   └── Reparo Teams/
│   └── Instaladores/
│       ├── ClaudeCLI/
│       ├── Dbeaver/
│       ├── Docker/
│       ├── Gitbash/
│       ├── ODBC/
│       └── WSL/
├── wap/                              # Documentação institucional das ferramentas
│   ├── README.md                     # Índice
│   ├── Apresentacao-WAP.md
│   ├── Padrao-Oficial-WAP.md         # Padrão para novos scripts
│   ├── PowerBI.md                    # Telemetria CSV e métricas
│   ├── Reparo-*.md
│   └── Instalador-*.md
├── assets/
├── LICENSE
└── README.md
```

> Este repositório não contém dados do ambiente corporativo. Antes de usar, substitua os valores `coloque_seu_path_aqui` (e `coloque_seu_*_aqui`) indicados no README de cada ferramenta.

<a id="requisitos"></a>
## 💻 Requisitos

- Windows 10 ou superior
- PowerShell 5.1 ou superior
- Privilégios administrativos para reparos de sistema (Rápido, Avançado, Impressora etapa 1) e instaladores de máquina; Teams, SAP e instaladores por usuário rodam no contexto do usuário
- Módulo Active Directory (opcional: usado apenas na coluna `Departamento` da telemetria; sem ele o valor fica `Unknown` e a execução continua)
- Runtime WSL instalado (apenas para o Docker)
- Internet e WinGet (Git Bash e Claude CLI)

<a id="como-usar"></a>
## ▶️ Como usar

1. Clone o repositório:
```bash
git clone https://github.com/ViCodax/Workplace-Automation-Platform.git
cd Workplace-Automation-Platform/scripts
```

2. Abra o `README.md` da ferramenta desejada (ex.: `Executaveis/Reparo Teams/README.md`), substitua os valores `coloque_seu_path_aqui` e execute no contexto indicado:
```powershell
.\WAP-ReparoTeams.ps1
.\WAP-ReparoSAP.ps1 -SapSourcePath 'coloque_seu_path_aqui'
.\WAP-ReparoImpressora-Usuario.ps1 -PrinterServer 'coloque_seu_servidor_aqui' -PrinterShare 'NOME_DA_IMPRESSORA'
```

3. Acompanhe o log em `C:\Temp\WAP\Logs` para validar o resultado.

> ⚠️ Teste os scripts em uma máquina de homologação antes de qualquer deploy em massa.

<a id="sccm"></a>
## 📦 Distribuição via SCCM

Os scripts são empacotados por responsabilidade e distribuídos via **Microsoft Configuration Manager (SCCM)** em **self-service** no Software Center, possibilitando:

- Execução silenciosa em massa
- Coleta de logs padronizados para auditoria
- Distribuição segmentada por coleção de dispositivos
- Autoatendimento do usuário final, sem abertura de chamado

**Contexto e códigos de retorno**
- Separação entre operações de máquina (SYSTEM) e de usuário (perfil), declarada por ferramenta
- `0` = sucesso, `1` = falha, `3010` = concluído com reinicialização requerida (usado pelo instalador WSL)

**Boas práticas de empacotamento**
- Uma pasta de source por ferramenta (evita inflar o tamanho do pacote)
- Execução com `-ExecutionPolicy Bypass`
- Método de detecção baseado em arquivo de log ou chave de registro
- Homologar o pacote e o comportamento pelo SCCM antes de publicar

Novos scripts seguem o [Padrão Oficial WAP](wap/Padrao-Oficial-WAP.md).

<a id="telemetria"></a>
## 📊 Telemetria

Os scripts PowerShell exportam uma linha CSV por execução, com fallback local quando a rede não está disponível (padrão: `C:\Temp\WAP\JsonBackup`, nome histórico). Campos comuns:

- `Data`, `Ferramenta`, `Departamento`, `Status`, `DuracaoSegundos`, `Erro` e `TempoEconomizadoMins`
- Alguns scripts exportam também `AcessoRede` ou `UptimeHoras`

Os esquemas ainda **não são idênticos** entre todas as ferramentas; o [Padrão Oficial](wap/Padrao-Oficial-WAP.md) define o esquema alvo para novos scripts (incluindo `CategoriaErro` e `TentativasRetry`). O instalador Docker via CMD grava apenas log, sem CSV.

Os CSVs são consumidos no **Power BI** (volume, taxa de sucesso, duração e falhas). `TempoEconomizadoMins` é uma estimativa fixa de ROI, não uma medição. Detalhes em [`wap/PowerBI.md`](wap/PowerBI.md).

<a id="roadmap"></a>
## 🗺️ Roadmap

Prioridades: confiabilidade, clareza de ownership, consistência entre implementação e documentação, e validação da distribuição via SCCM. Itens abaixo são **ideias futuras**, sem escopo, responsáveis ou homologação definidos; não são entregas.

- [ ] Unificar o esquema de telemetria entre as ferramentas, conforme o Padrão Oficial
- [ ] Evolução do painel de telemetria em Power BI
- [ ] Abertura automática de chamado no TOPdesk via Webhook/API
- [ ] Novas automações de suporte (VPN, perfil de usuário)
- [ ] Versão com interface gráfica (GUI) para usuários finais
- [ ] Pacotes prontos para Intune

<a id="contribuicao"></a>
## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir uma *issue* com sugestões, bugs encontrados ou ideias de novas automações, ou enviar um *pull request*.

<a id="licenca"></a>
## 📄 Licença

Este projeto está licenciado sob os termos da **Licença MIT** — veja o arquivo [LICENSE](./LICENSE) para mais detalhes.

<a id="autor"></a>
## 👤 Autor

**Vinicius Correia**
Workplace Automation Specialist

[LinkedIn](https://www.linkedin.com/in/viniciuscdantas) · [GitHub](https://github.com/ViCodax)
