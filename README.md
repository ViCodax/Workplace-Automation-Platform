<div align="center">

# ⚙️ Workplace Automation Platform (WAP)

### Toolkit de automação em PowerShell para suporte Workplace, troubleshooting e redução de intervenções manuais.

<img src="https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge&labelColor=0b241c" />
<img src="https://img.shields.io/badge/Status-Em%20Produção-22C55E?style=for-the-badge&labelColor=0b241c" />
<img src="https://img.shields.io/badge/PowerShell-5.1%2B-22C55E?style=for-the-badge&logo=powershell&logoColor=white&labelColor=0b241c" />
<img src="https://img.shields.io/badge/SCCM-Compatível-22C55E?style=for-the-badge&logo=microsoft&logoColor=white&labelColor=0b241c" />

</div>

<br/>

## 📑 Sumário

- [Sobre](#sobre)
- [Objetivos](#objetivos)
- [Ferramentas disponíveis](#ferramentas)
- [Estrutura do repositório](#estrutura)
- [Requisitos](#requisitos)
- [Como usar](#como-usar)
- [Distribuição via SCCM](#sccm)
- [Roadmap](#roadmap)
- [Contribuição](#contribuicao)
- [Licença](#licenca)
- [Autor](#autor)

<br/>

<a id="sobre"></a>
## 📌 Sobre

A **Workplace Automation Platform (WAP)** é uma iniciativa de automação focada na melhoria de processos técnicos e repetitivos de suporte, construída em **PowerShell** e pensada para tecnologias de distribuição corporativa.

As ferramentas foram originalmente desenvolvidas como parte de uma plataforma corporativa de automação para Workplace e, posteriormente, adaptadas para funcionar de forma independente do ambiente corporativo original.

O repositório atual contém as **três primeiras ferramentas** de automação desenvolvidas para a plataforma. O projeto foi concebido pensando em ambientes corporativos, incluindo distribuição centralizada por meio do **Microsoft Configuration Manager (SCCM)** e geração estruturada de logs de execução.

<br/>

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
| 📊 Coletar dados de execução | Logs estruturados para análise operacional e telemetria |

<br/>

<a id="ferramentas"></a>
## 🛠️ Ferramentas disponíveis

### 1. Teams Repair
**Status:** 🟢 Produção

Automatiza procedimentos comuns de troubleshooting do Microsoft Teams.

- Encerramento de processos do Teams
- Encerramento de processos do Microsoft Edge WebView
- Limpeza do cache do Teams
- Múltiplas tentativas de limpeza com lógica de retry
- Reinicialização do aplicativo Teams
- Geração de logs de execução
- Categorização de erros
- Identificação do usuário e da estação de trabalho
- Consulta opcional ao departamento do usuário no Active Directory

### 2. Windows Quick Repair
**Status:** 🟢 Produção

Executa um conjunto de procedimentos rápidos de troubleshooting e manutenção do Windows, utilizados frequentemente no suporte diário de Workplace.

- Limpeza do cache DNS
- Reset do Winsock
- Reset do TCP/IP
- Limpeza da pasta TEMP do usuário
- Limpeza da pasta TEMP do Windows
- Limpeza do cache do Teams
- Reinicialização do Windows Explorer
- Coleta de informações do sistema
- Geração de logs de execução
- Tratamento e categorização de erros

### 3. Windows Advanced Repair
**Status:** 🟢 Produção

Disponibiliza uma rotina mais completa de troubleshooting e reparo do Windows para problemas recorrentes do sistema operacional.

- System File Checker (SFC)
- Restauração da integridade do sistema com DISM
- Verificação de disco com CHKDSK
- Otimização do disco
- Reset dos serviços do Windows Update
- Limpeza do cache do Windows Update
- Diagnóstico do sistema
- Coleta de informações de rede
- Monitoramento de espaço disponível em disco
- Coleta do tempo de atividade do sistema
- Geração de logs de execução
- Categorização de erros

<br/>

<a id="estrutura"></a>
## 📂 Estrutura do repositório

```
Workplace-Automation-Platform-ptbr/
├── scripts/
│   ├── Teams-Repair.ps1
│   ├── Windows-Quick-Repair.ps1
│   └── Windows-Advanced-Repair.ps1
├── assets/
│   └── screenshots/
├── LICENSE
└── README.md
```

<br/>

<a id="requisitos"></a>
## 💻 Requisitos

- Windows 10 ou superior
- PowerShell 5.1 ou superior
- Execução com privilégios administrativos (necessário para reparos de sistema)
- Módulo Active Directory (opcional, apenas para consulta de departamento do usuário)

<br/>

<a id="como-usar"></a>
## ▶️ Como usar

1. Clone o repositório:
   ```bash
   git clone https://github.com/ViCodax/Workplace-Automation-Platform-ptbr.git
   cd Workplace-Automation-Platform-ptbr/scripts
   ```

2. Execute o script desejado em um terminal PowerShell com privilégios administrativos:
   ```powershell
   .\Teams-Repair.ps1
   ```

3. Acompanhe os logs de execução gerados automaticamente para validar o resultado da automação.

> ⚠️ Recomenda-se testar os scripts em ambiente controlado antes de distribuir em produção.

<br/>

<a id="sccm"></a>
## 📦 Distribuição via SCCM

Os scripts foram projetados para permitir empacotamento e distribuição centralizada via **Microsoft Configuration Manager (SCCM)**, possibilitando:

- Execução silenciosa em massa
- Coleta de logs padronizados para auditoria
- Agendamento e distribuição segmentada por coleção de dispositivos

<br/>

<a id="roadmap"></a>
## 🗺️ Roadmap

- [ ] Adicionar novas automações de suporte (impressoras, VPN, perfil de usuário)
- [ ] Telemetria centralizada em Power BI
- [ ] Versão com interface gráfica (GUI) para usuários finais
- [ ] Publicação de pacotes prontos para Intune

<br/>

<a id="contribuicao"></a>
## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir uma *issue* com sugestões, bugs encontrados ou ideias de novas automações, ou enviar um *pull request*.

<br/>

<a id="licenca"></a>
## 📄 Licença

Este projeto está licenciado sob os termos da **Licença MIT** — veja o arquivo [LICENSE](./LICENSE) para mais detalhes.

<br/>

<a id="autor"></a>
## 👤 Autor

<div align="center">

**Vinicius Correia**
<br/>
Workplace Automation Specialist

<a href="https://www.linkedin.com/in/viniciuscdantas"><img src="https://img.shields.io/badge/LinkedIn-viniciuscdantas-22C55E?style=for-the-badge&logo=linkedin&logoColor=white&labelColor=0b241c" /></a>
<a href="https://github.com/ViCodax"><img src="https://img.shields.io/badge/GitHub-ViCodax-22C55E?style=for-the-badge&logo=github&logoColor=white&labelColor=0b241c" /></a>

</div>
