# WAP - Instalador independente do Docker CE

## Responsabilidade

Este aplicativo SCCM importa Ubuntu com Docker CE no perfil do usuário.
Não instala o runtime WSL, não habilita recursos Windows e não depende de
arquivos, flags ou execução anterior do instalador WAP de WSL.
WSL pode ter sido instalado por qualquer método compatível.

Os instaladores usam o nome `DockerInstall`, sem referência a fases de um
pacote unificado. Docker Desktop não é utilizado.

## Conteúdo do pacote

```text
Docker/
	Script/
		DockerInstall.ps1
		DockerInstall-Usuario.ps1
		DockerInstall.cmd
		DockerLog.js
	Util/
		firstrun-user.sh
		Cloudflare_CA.pem   (a fornecer; veja abaixo)
		provision-docker.sh
```

O certificado de CA da sua organização (no exemplo, `Cloudflare_CA.pem`) **não é
distribuído neste repositório**. Se a sua rede intercepta TLS (proxy, WARP etc.),
forneça o certificado raiz correspondente em `Util/` ou já embutido na imagem.

A imagem homologada deve conter Docker CE, Compose, certificado corporativo,
systemd habilitado em `/etc/wsl.conf` e DNS configurado. O instalador valida
Docker/Compose e inicia/habilita o daemon; não reinstala pacotes via apt.
`provision-docker.sh` é uma ferramenta para preparar a imagem base, não é
chamado por nenhum dos instaladores Windows.

A imagem pode estar no pacote (`Util/ubuntu-wap.wsl`) ou no compartilhamento:

```text
coloque_seu_path_aqui\ubuntu-wap.wsl
```

O próprio Docker recupera a imagem. O usuário precisa ter permissão de leitura
nessa origem quando ela não estiver no cache ou no pacote SCCM.

## Execução SCCM

Configurar aplicativo de **usuário**, executado como usuário logado, não SYSTEM.
Manter a estrutura `Script` e `Util` ao distribuir o conteúdo.

Entrada sem PowerShell, a partir da raiz do pacote:

```bat
cmd.exe /d /c "Script\DockerInstall.cmd"
```

O `.cmd` não chama PowerShell. Manter `DockerLog.js` junto dele: o conversor
usa Windows Script Host (`cscript.exe`) e `ADODB.Stream` para gravar o log
em UTF-8. Esses componentes precisam estar permitidos pela política corporativa.
Opcionalmente recebe o caminho
completo da imagem no primeiro argumento. A distro nessa entrada é `Ubuntu`.

Entrada PowerShell, para máquinas onde PowerShell funciona:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Script\DockerInstall-Usuario.ps1"
```

O wrapper chama `DockerInstall.ps1` na mesma pasta do pacote, não em `C:\WAP`.
Aceita `-DistroName`, `-RootfsFileName`, `-FirstRunFileName`, `-BasePath` e
`-RootfsSourcePath` e encaminha os argumentos ao instalador.
Configurar retornos `0` = sucesso e `1` = falha.

## Fluxo e verificações

1. Rejeita SYSTEM e verifica `wsl.exe`, `wsl --version` e `wsl --status` antes de acessar o payload.
2. Consulta distribuições do usuário. Runtime indisponível não é tratado como distro ausente.
3. Se Ubuntu não existir, recupera a imagem para cache do usuário e importa com `--version 2`.
4. Comprova registro WSL2, execução Linux, systemd, Docker CLI, Compose e resposta de `docker info`.
5. Injeta first-run normalizado para LF e verifica sua sintaxe com `bash -n` dentro da distro.
6. Encerra a distro e grava a flag somente após sucesso das verificações.

A entrada CMD também aplica o DNS configurado em `WAP_CORPORATE_DNS` (em `Util/firstrun-user.sh`) e fallback `1.1.1.1`
durante a instalação, executando first-run com `--configure-network`.
Esse modo não solicita senha nem cria usuário. Ele corrige imagens que têm
`generateResolvConf=false`, mas ainda apontam para o stub `127.0.0.53` sem DNS
configurado. O modo interativo reutiliza a mesma configuração.

WSL pode estar disponível sem nenhuma distro. O pre-check valida o runtime;
a prova de inicialização da VM/Linux acontece após importar a imagem.
Virtualização indisponível ou reboot pendente pode ser detectado nessa etapa.

Uma distro existente que não inicia, não é WSL2 ou não possui Docker funcional
gera falha. Ela não é removida, reimportada nem convertida automaticamente.
Uma flag existente não basta: Docker é novamente validado antes de retornar sucesso.

## Primeiro acesso interativo

Abrir a distro pelo terminal do Windows:

```bat
wsl -d Ubuntu
```

O first-run solicita usuário Linux e senha, configura `sudo`, grupo `docker`,
DNS e usuário padrão. Não roda sem terminal interativo. Interrompe falhas antes
da flag `/etc/wap-firstrun.done`; a conta de uma tentativa parcial pode ser
retomada usando o mesmo nome. Contas existentes não criadas por essa tentativa
não têm suas senhas sobrescritas.

A conclusão do instalador Windows significa imagem/Docker prontos e first-run
instalado. Não significa que o usuário Linux já foi criado.
Depois da configuração, abrir novamente e validar:

```bash
whoami
id
docker info
docker compose version
docker run hello-world
```

`hello-world` valida adicionalmente acesso ao Docker Hub, DNS e certificados;
esse teste de rede não é executado automaticamente pelo instalador.

## Cache, logs e telemetria

- Distro: `%LOCALAPPDATA%\WSL\Ubuntu`.
- Cache e flags: `%LOCALAPPDATA%\WAP\Docker`.
- Log PowerShell: `%LOCALAPPDATA%\WAP\Logs\WAP_DockerInstall.log`.
- Log CMD: `C:\Temp\WAP\Logs\WAP_DockerInstall.log`.
- O log CMD usa UTF-8: `WSL_UTF8=1` evita a saída UTF-16 do WSL, e o conversor normaliza a saída OEM do `ipconfig`. O console usa temporariamente a página 65001 e retorna à anterior ao finalizar. Os códigos de retorno dos comandos são preservados.
- Logs CMD anteriores sem o cabeçalho `WAP_LOG_ENCODING=UTF-8` são preservados como `WAP_DockerInstall_legacy_<identificador>.log`, na mesma pasta, antes de iniciar o arquivo UTF-8. O histórico antigo não é recodificado, pois contém codificações misturadas.
- O CMD testa a gravação do log antes de validar a identidade e imprime seu caminho. Se não conseguir criar ou gravar o arquivo central, tenta `%TEMP%\WAP\Logs` e registra um aviso nesse log alternativo. Não eleva privilégios nem altera permissões da pasta.
- CSV PowerShell: `DockerInstall_<COMPUTERNAME>_yyyyMMdd_HHmmss.csv`, na rede WAP; backup em `%LOCALAPPDATA%\WAP\JsonBackup` quando a rede estiver indisponível.
- CSV CMD: `DockerInstall_<COMPUTERNAME>_<identificador>.csv`, com o mesmo esquema de colunas; fallback em `%LOCALAPPDATA%\WAP\JsonBackup` (ou `%TEMP%\WAP\JsonBackup` se `LOCALAPPDATA` não estiver definido). O campo Departamento fica como `Unknown`; `--check-only` não gera telemetria.
- `--csv-test` executa apenas `ipconfig /flushdns` e grava o mesmo esquema CSV em `%TEMP%\WAP\CSVTest`, sem acessar a distro Docker ou enviar telemetria para a rede. A tarefa `WAP: testar geracao CSV Docker via CMD` executa esse teste.
- O identificador CSV PowerShell e CMD `WAP-Docker-Fase2` foi mantido para compatibilidade com métricas existentes; o formato das colunas não mudou.
- `C:\WAP\Docker` é apenas uma origem legada opcional de leitura para a entrada CMD.

Após renomear, atualizar o comando e eventuais referências/detecções de arquivo
no SCCM e redistribuir o conteúdo. Distro, cache e flags mantêm os mesmos nomes;
a renomeação não exige reimportação. Logs anteriores permanecem com o nome antigo.

Não usar uma flag isolada como prova de funcionamento na detecção SCCM.
A detecção deve ocorrer no contexto do usuário e considerar a distro WSL2
registrada, Docker funcional e a flag de instalação desse perfil.

## Homologação local em 2026-10-02

Testes executados via CMD, sem PowerShell, com runtime WSL `2.7.3.0`:

- Importação nova de `ubuntu-wap.wsl` em `Ubuntu-WAP-Homologacao`, preservando Ubuntu.
- Inicialização Linux, WSL2, systemd, Docker `29.7.2` e Compose `v5.5.0`.
- Execução do instalador CMD sobre Ubuntu, injeção/sintaxe first-run e configuração DNS.
- Download de `hello-world` no Docker Hub e execução do container com sucesso.
- Reexecução do instalador sem reimportar a distro.
- Remoção autorizada de Ubuntu e reinstalação completa pelo CMD, incluindo importação da imagem em cache, DNS, Docker e first-run.
- Download/execução de `hello-world` e reexecução bem-sucedidos após essa reinstalação, preservando `Ubuntu-WAP-Homologacao`.

A rodada com Ubuntu removido revelou um falso positivo na detecção: buscar
todos os dados do registro também encontrava `Flavor=ubuntu` de outra distro.
O CMD agora enumera as entradas e compara explicitamente `DistributionName`
com `Ubuntu`, sem depender dos filtros de busca de `reg query`.
O cache da imagem foi preservado: essa rodada validou nova importação, não
um novo download da imagem WSL. A conta Linux anterior foi removida junto
com a distro e precisa ser recriada no próximo primeiro acesso.

Nesta máquina, a chamada de validação com `-d "Ubuntu"` reproduziu
`WSL_E_DISTRO_NOT_FOUND`; `-d Ubuntu` funcionou. O CMD passa o nome fixo sem
aspas, mantendo caminhos de arquivos protegidos por aspas.

O primeiro acesso interativo com criação de usuário/senha não foi executado
automaticamente. A distro `Ubuntu-WAP-Homologacao` permanece para inspeção;
não deve ser apagada sem confirmar que seus dados podem ser descartados.

## Homologação SCCM pendente

Redistribuir o conteúdo atualizado e validar a execução como usuário via SCCM.
A imagem usada nestes testes já contém Docker; o MSI WSL `3.0.1.0` não foi
instalado por esses testes. Validar também WSL ausente, runtime quebrado,
reboot pendente, Ubuntu existente sem Docker, segundo usuário e primeiro
acesso interativo interrompido/retomado.
Não remover uma distro de produção para testar: `wsl --unregister` apaga seus dados.
