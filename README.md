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

As ferramentas foram originalmente desenvolvidas como parte de uma plataforma corporativa de automação para Workplace e, posteriormente, adaptadas para funcionar de forma independente do ambiente corporativo original.

Hoje o repositório reúne **rotinas de reparo, diagnóstico e instaladores automatizados**, com distribuição centralizada via **Microsoft Configuration Manager (SCCM)**, geração estruturada de logs e coleta de telemetria de execução.

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

As ferramentas seguem o padrão visual da plataforma:
🔵 **Reparo simples** · 🟠 **Reparo avançado** · 🟢 **Instaladores**

---

### 🔵 1. Teams Repair
**Status:** ✅ Funcional

Automatiza procedimentos comuns de troubleshooting do Microsoft Teams.
- Encerramento de processos do Teams e do Microsoft Edge WebView
- Limpeza do cache do Teams
- Múltiplas tentativas de limpeza com lógica de retry
- Reinicialização do aplicativo Teams
- Identificação do usuário e da estação de trabalho
- Consulta opcional ao departamento do usuário no Active Directory
- Geração de logs e categorização de erros

---

### 🔵 2. Windows Quick Repair
**Status:** ✅ Funcional

Executa um conjunto de procedimentos rápidos de troubleshooting e manutenção do Windows, utilizados frequentemente no suporte diário de Workplace.
- Limpeza do cache DNS
- Reset do Winsock e do TCP/IP
- Limpeza das pastas TEMP do usuário e do Windows
- Limpeza do cache do Teams
- Reinicialização do Windows Explorer
- Coleta de informações do sistema
- Geração de logs e categorização de erros

---

### 🟠 3. Windows Advanced Repair
**Status:** ✅ Funcional

Disponibiliza uma rotina mais completa de troubleshooting e reparo do Windows para problemas recorrentes do sistema operacional.
- System File Checker (SFC)
- Restauração da integridade do sistema com DISM
- Verificação de disco com CHKDSK e otimização
- Reset dos serviços e limpeza do cache do Windows Update
- Diagnóstico do sistema e coleta de informações de rede
- Monitoramento de espaço em disco e tempo de atividade
- Geração de logs e categorização de erros

---

### 🔵 4. SAP List Fix
**Status:** ✅ Funcional

Corrige e padroniza a lista de conexões do SAP GUI, eliminando a configuração manual por usuário.
- Restauração do arquivo de configuração oficial
- Padronização das entradas de ambiente
- Geração de log de execução

---

### 🔵 5. Printer Repair
**Status:** 🟢 Produção

Correção automatizada de falhas recorrentes de impressão.
- Tratamento do erro `0x00000709` (impressora padrão)
- Reset do spooler de impressão e limpeza da fila
- Revalidação das conexões com impressoras de rede
- Geração de logs e categorização de erros

---

### 🟢 6. Docker Install & Troubleshooting
**Status:** 🟢 Produção

Instalação, provisionamento e recuperação completa do ambiente Docker + WSL.
- Instalação silenciosa do Docker Desktop
- Provisionamento e validação do WSL e das distros
- Ajustes de proxy e certificados corporativos
- Verificação e reinício dos serviços do Docker
- Rotina de diagnóstico para falhas de ambiente
- Geração de logs e categorização de erros

---

### 🟢 7. DBeaver Install & Config
**Status:** ✅ Funcional

Instalação do DBeaver com configuração automatizada do ambiente de trabalho.
- Instalação silenciosa da aplicação
- Injeção de workspace padronizado
- Configuração de ODBC via registro
- Conexões corporativas no padrão de autenticação IDP/SSO

---

### 🟢 8. Git Bash Install
**Status:** ✅ Funcional

Instalação silenciosa do Git Bash com parâmetros padronizados do ambiente corporativo.

---

### 🟢 9. Claude CLI Install
**Status:** ✅ Funcional

Instalação automatizada da CLI, com tratamento de proxy, certificados e dependências do ambiente corporativo.

<a id="estrutura"></a>
## 📂 Estrutura do repositório

```
Workplace-Automation-Platform/
├── scripts/
│   ├── Teams-Repair.ps1
│   ├── Windows-Quick-Repair.ps1
│   ├── Windows-Advanced-Repair.ps1
│   ├── SAP-List-Fix.ps1
│   ├── Printer-Repair.ps1
│   ├── Docker-Install.ps1
│   ├── DBeaver-Install.ps1
│   ├── GitBash-Install.ps1
│   └── ClaudeCLI-Install.ps1
├── assets/
│   ├── icons/
│   └── screenshots/
├── LICENSE
└── README.md
```

<a id="requisitos"></a>
## 💻 Requisitos

- Windows 10 ou superior
- PowerShell 5.1 ou superior
- Execução com privilégios administrativos (necessário para reparos de sistema e instaladores)
- Módulo Active Directory (opcional, apenas para consulta de departamento do usuário)
- WSL 2 habilitado (apenas para as automações de Docker)

<a id="como-usar"></a>
## ▶️ Como usar

1. Clone o repositório:
```bash
git clone https://github.com/ViCodax/Workplace-Automation-Platform.git
cd Workplace-Automation-Platform/scripts
```

2. Execute o script desejado em um terminal PowerShell com privilégios administrativos:
```powershell
.\Teams-Repair.ps1
```

3. Acompanhe os logs de execução gerados automaticamente para validar o resultado da automação.

> ⚠️ Recomenda-se testar os scripts em ambiente controlado antes de distribuir em produção.

<a id="sccm"></a>
## 📦 Distribuição via SCCM

Os scripts são empacotados e distribuídos de forma centralizada via **Microsoft Configuration Manager (SCCM)**, disponibilizados em **self-service** no Software Center, possibilitando:

- Execução silenciosa em massa
- Coleta de logs padronizados para auditoria
- Agendamento e distribuição segmentada por coleção de dispositivos
- Autoatendimento do usuário final, sem abertura de chamado

**Boas práticas de empacotamento**
- Uma pasta de source por ferramenta (evita inflar o tamanho do pacote)
- Execução com `-ExecutionPolicy Bypass`
- Método de detecção baseado em arquivo de log ou chave de registro

<a id="telemetria"></a>
## 📊 Telemetria

Todos os scripts registram dados de execução em formato estruturado (**CSV**), permitindo análise operacional:

- Nome e versão da ferramenta
- Usuário, hostname e departamento
- Data/hora de início e fim, com duração total
- Resultado final (sucesso/erro) e categoria do erro

Esses dados alimentam um **dashboard em Power BI**, usado para acompanhar adoção, volume de execuções, taxa de sucesso e economia de atendimentos manuais.

<a id="roadmap"></a>
## 🗺️ Roadmap

- [ ] Abertura automática de chamado no TOPdesk via Webhook/API a cada execução
- [ ] Novas automações de suporte (VPN, perfil de usuário)
- [ ] Evolução do painel de telemetria em Power BI
- [ ] Versão com interface gráfica (GUI) para usuários finais
- [ ] Publicação de pacotes prontos para Intune

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
