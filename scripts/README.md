# Pacote WAP Default

Estas versoes nao possuem caminho de rede, servidor de impressao, IP, DNS ou telemetria de ambiente preconfigurados. Os scripts originais em `Scripts/` e os arquivos em `BACKUPS/` nao foram alterados.

Por padrao, a telemetria CSV dos reparos e gravada em `C:\Temp\WAP\JsonBackup`. Para enviar a outro local, informe `-TelemetryPath "C:\SEU_DIRETORIO"` ou um compartilhamento UNC gravavel pela conta que executa o script.

## Reparos

| Script | Configuracao necessaria |
| --- | --- |
| `WAP-ReparoAvancado.ps1` | Execute como administrador. Telemetria e opcional. |
| `WAP-ReparoRapido.ps1` | Execute como administrador. Uma reinicializacao pode ser necessaria apos o reset de rede. |
| `WAP-ReparoTeams.ps1` | Execute no contexto do usuario cujo Teams sera reparado. |
| `WAP-ReparoSAP.ps1` | Informe `-SapSourcePath` apontando para a pasta com `SAPUILandscape.xml` e `SAPUILandscapeGlobal.xml`. |
| `WAP-ReparoImpressora.ps1` | Execute como administrador e informe `-DriverName` e `-DriverInfPath`. O pacote do driver deve ser fornecido pelo seu ambiente. |
| `WAP-ReparoImpressora-Usuario.ps1` | Execute como o usuario final e informe `-PrinterServer` e `-PrinterShare`. |

Exemplos:

```powershell
.\WAP-ReparoSAP.ps1 -SapSourcePath '\\SERVIDOR\Compartilhamento\SAP'
.\WAP-ReparoImpressora.ps1 -DriverName 'NOME EXATO DO DRIVER' -DriverInfPath 'C:\Drivers\driver.inf'
.\WAP-ReparoImpressora-Usuario.ps1 -PrinterServer 'SERVIDOR-IMPRESSAO' -PrinterShare 'NOME_DA_IMPRESSORA'
```

## Instaladores

| Script | Requisito |
| --- | --- |
| `WAP-ClaudeIII-Install.ps1` | Internet e WinGet. Se o WinGet falhar, usa o instalador oficial de `claude.ai`. Execute no contexto do usuario. |
| `WAP-GitBash-Install-Usuario.ps1` | Internet e WinGet. Se necessario, baixa o instalador oficial mais recente do Git for Windows. Execute no contexto do usuario. |
| `WAP-GitBash-Install.ps1` | Encaminha para a variante por usuario. Para deploys de maquina, agende a variante por usuario apos o logon. |
| `WAP-DBeaver-Install.ps1` | Informe `-WorkspaceSourcePath` com as pastas `drivers` e `workspace6`. Se DBeaver ainda nao estiver instalado, informe tambem `-DBeaverInstallerPath` com o executavel do instalador do DBeaver. |

Exemplo:

```powershell
.\WAP-DBeaver-Install.ps1 -WorkspaceSourcePath '\\SERVIDOR\Pacotes\DBeaver\workspace-default' -DBeaverInstallerPath '\\SERVIDOR\Pacotes\DBeaver\dbeaver-installer.exe'
```

## Docker WSL

Coloque na mesma pasta de payload os arquivos abaixo antes de executar a Fase 1:

```text
DockerFase2.ps1
firstrun-user.sh
ubuntu-docker.wsl
wsl.<versao>.x64.msi   (opcional; necessario somente quando o WSL nao estiver disponivel no Windows)
```

A imagem `ubuntu-docker.wsl` deve ser criada e homologada pela sua organizacao, com Docker instalado. A Fase 1 deve ser executada como administrador ou `SYSTEM`:

```powershell
.\DockerFase1.ps1 -PayloadPath '\\SERVIDOR\Pacotes\Docker' -DistroName 'Ubuntu-Docker' -RootfsFileName 'ubuntu-docker.wsl'
```

Ela retorna `3010` quando concluir para solicitar reinicializacao. A Fase 2 roda no proximo logon, importa a distribuicao no perfil do usuario e instala o `firstrun-user.sh`. No primeiro acesso a distribuicao, o usuario Linux e a senha serao solicitados.

## Observacoes

- Os scripts que tentam consultar Active Directory usam isso somente para a coluna opcional `Departamento` da telemetria. Sem modulo ou dominio AD, o valor permanece `Unknown` e o reparo continua.
- Teste os scripts em uma maquina de homologacao antes de qualquer deploy em massa.