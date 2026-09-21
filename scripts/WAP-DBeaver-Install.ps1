# ==========================================
# WAP - DBeaver Configuration (Workspace Setup)
# Descrição: Injeta workspace6 pré-configurado
# Informe a pasta que contem drivers e workspace6 de sua organizacao.
# ==========================================

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceSourcePath,

    [string]$DBeaverInstallerPath = "",

    [string]$TelemetryPath = ""
)

# ---- 0) Re-lancar em 64-bit se cair em 32-bit (SysWOW64) ----
if ([IntPtr]::Size -eq 4 -and $env:PROCESSOR_ARCHITEW6432) {
    $ps64 = Join-Path $env:WINDIR "SysNative\WindowsPowerShell\v1.0\powershell.exe"
    & $ps64 -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

$ErrorActionPreference = 'Stop'

# ---- 1) Log ANTES de qualquer trabalho ----
$LogPath = "C:\Temp\WAP\Logs"
$JsonPathBackup = "C:\Temp\WAP\JsonBackup"
$JsonPath = if ([string]::IsNullOrWhiteSpace($TelemetryPath)) { $JsonPathBackup } else { $TelemetryPath }

New-Item -ItemType Directory -Force -Path $LogPath, $JsonPathBackup | Out-Null
$LogFile = Join-Path $LogPath "WAP_DBeaverInstall.log"

$Inicio            = Get-Date
$Status            = "Sucesso"
$Erro              = ""
$ErrorCategory     = "Nenhum"
$Tentativa         = 0
$NetworkAccessible = $false

Add-Content $LogFile "=========================================="
Add-Content $LogFile "WAP - DBeaver Configuration (Workspace)"
Add-Content $LogFile "Bitness PS........: $([IntPtr]::Size * 8) bits"
Add-Content $LogFile "Identidade........: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Add-Content $LogFile "Computador........: $env:COMPUTERNAME"
Add-Content $LogFile "=========================================="

# ---- 2) Funções auxiliares (incorporadas para compatibilidade SCCM) ----
function Get-WAP-ExtractedUser {
    param()
    $LoggedUser = Get-WAP-LoggedUser

    if ([string]::IsNullOrWhiteSpace($LoggedUser) -or $LoggedUser -eq "Unknown") {
        return "Unknown"
    }

    if ($LoggedUser -like "*\*") {
        $User = $LoggedUser.Split('\')[-1]
    }
    elseif ($LoggedUser -like "*@*") {
        $User = $LoggedUser.Split('@')[0]
    }
    else {
        $User = $LoggedUser
    }

    if ($User -like "*$") {
        return "Unknown"
    }

    return $User
}

function Get-WAP-LoggedUser {
    param()
    try {
        $LoggedUser = (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).UserName
        if (-not [string]::IsNullOrWhiteSpace($LoggedUser) -and $LoggedUser -like "*\*" -and $LoggedUser -notlike "*$") {
            return $LoggedUser
        }
    }
    catch {}

    try {
        $ExplorerProcess = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" -ErrorAction Stop |
            Sort-Object CreationDate -Descending |
            Select-Object -First 1

        if ($ExplorerProcess) {
            $Owner = Invoke-CimMethod -InputObject $ExplorerProcess -MethodName GetOwner -ErrorAction Stop
            if ($Owner -and $Owner.User -and $Owner.Domain) {
                return "$($Owner.Domain)\$($Owner.User)"
            }
        }
    }
    catch {}

    try {
        $LastLoggedOnUser = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name LastLoggedOnUser -ErrorAction Stop).LastLoggedOnUser
        if (-not [string]::IsNullOrWhiteSpace($LastLoggedOnUser)) {
            return $LastLoggedOnUser
        }
    }
    catch {}

    return "Unknown"
}

function Get-WAP-UserProfilePath {
    param(
        [string]$LoggedUser
    )

    if ([string]::IsNullOrWhiteSpace($LoggedUser) -or $LoggedUser -eq "Unknown") {
        return $null
    }

    $CandidateUser = if ($LoggedUser -like "*\*") {
        $LoggedUser.Split('\')[-1]
    }
    elseif ($LoggedUser -like "*@*") {
        $LoggedUser.Split('@')[0]
    }
    else {
        $LoggedUser
    }

    if ([string]::IsNullOrWhiteSpace($CandidateUser)) {
        return $null
    }

    try {
        $ProfileKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -ErrorAction Stop
        foreach ($ProfileKey in $ProfileKeys) {
            $ProfileImagePath = (Get-ItemProperty -Path $ProfileKey.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
            if (-not [string]::IsNullOrWhiteSpace($ProfileImagePath)) {
                $ProfileLeaf = Split-Path $ProfileImagePath -Leaf
                if ($ProfileLeaf -ieq $CandidateUser) {
                    return $ProfileImagePath
                }
            }
        }
    }
    catch {}

    $FallbackProfilePath = Join-Path "C:\Users" $CandidateUser
    if (Test-Path $FallbackProfilePath) {
        return $FallbackProfilePath
    }

    return $null
}

# (Variáveis já inicializadas no início do script)

# Pegar informações do usuário logado e Active Directory
$LoggedUser = Get-WAP-LoggedUser
$User = Get-WAP-ExtractedUser
$TargetProfilePath = Get-WAP-UserProfilePath -LoggedUser $LoggedUser

if ([string]::IsNullOrWhiteSpace($TargetProfilePath)) {
    $TargetProfilePath = $env:USERPROFILE
}

$TargetAppDataRoaming = Join-Path $TargetProfilePath "AppData\Roaming"
$DBeaverDataPath = Join-Path $TargetAppDataRoaming "DBeaverData"

Add-Content $LogFile "Usuario extraido: $User"
Add-Content $LogFile "Usuario de processo: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Add-Content $LogFile "Usuario alvo (detectado): $LoggedUser"
Add-Content $LogFile "Perfil alvo: $TargetProfilePath"
Add-Content $LogFile "DBeaverData alvo: $DBeaverDataPath"

$Department = "Unknown"
if ($User -and $User -ne "Unknown" -and $User -notlike "*$") {
    try {
        # Verificar se módulo ActiveDirectory está disponível
        if (-not (Get-Module -Name ActiveDirectory -ErrorAction Ignore)) {
            $null = Import-Module ActiveDirectory -ErrorAction Ignore -PassThru
        }
        
        if (Get-Module -Name ActiveDirectory -ErrorAction Ignore) {
            $ADUser = Get-ADUser -Identity $User -Properties Department -ErrorAction Ignore
            if ($ADUser -and $ADUser.Department) {
                $Department = $ADUser.Department
                Add-Content $LogFile "Departamento obtido de AD: $Department"
            }
        }
        else {
            Add-Content $LogFile "AVISO: Modulo ActiveDirectory nao disponivel"
        }
    }
    catch {
        Add-Content $LogFile "AVISO: Nao foi possivel obter departamento de AD: $($_.Exception.Message)"
    }
}
else {
    Add-Content $LogFile "AVISO: Usuario invalido ou conta de sistema ($User). Departamento nao disponivel."
}

# Cabeçalho do LOG
Add-Content $LogFile "=========================================="
Add-Content $LogFile "WAP - DBeaver Configuration (Workspace Setup)"
Add-Content $LogFile "Inicio: $Inicio"
Add-Content $LogFile "Usuario: $env:USERNAME"
Add-Content $LogFile "Computador: $env:COMPUTERNAME"
Add-Content $LogFile "=========================================="

try {
    # Parâmetros da Configuração
    Add-Content $LogFile "DBeaverData Path: $DBeaverDataPath"
    Add-Content $LogFile "========== INJECAO DE WORKSPACE =========="
    
    # Parámetros da Etapa 2
    $WorkspaceSourceBase = $WorkspaceSourcePath
    $DriversSourcePath = "$WorkspaceSourceBase\drivers"
    $MetadataSourcePath = "$WorkspaceSourceBase\workspace6\.metadata\.config"
    $GeneralSourcePath = "$WorkspaceSourceBase\workspace6\General\.dbeaver"
    
    $DriversDestPath = "$DBeaverDataPath\drivers"
    $MetadataDestPath = "$DBeaverDataPath\workspace6\.metadata\.config"
    $GeneralDestPath = "$DBeaverDataPath\workspace6\General\.dbeaver"
    
    Add-Content $LogFile "Source base: $WorkspaceSourceBase"
    Add-Content $LogFile "Drivers: $DriversSourcePath -> $DriversDestPath"
    Add-Content $LogFile "Metadata: $MetadataSourcePath -> $MetadataDestPath"
    Add-Content $LogFile "General: $GeneralSourcePath -> $GeneralDestPath"
    
    # Passo 1: Validar que DBeaver está instalado
    Add-Content $LogFile "Validando se DBeaver ja esta instalado..."
    $DBeaverPath = "C:\Program Files\DBeaver\dbeaver.exe"
    if (-not (Test-Path $DBeaverPath) -and -not [string]::IsNullOrWhiteSpace($DBeaverInstallerPath)) {
        if (-not (Test-Path $DBeaverInstallerPath -PathType Leaf)) {
            throw "Instalador DBeaver nao encontrado: $DBeaverInstallerPath"
        }
        Add-Content $LogFile "Instalando DBeaver com: $DBeaverInstallerPath"
        $InstallProcess = Start-Process -FilePath $DBeaverInstallerPath -ArgumentList '/S', '/allusers' -Wait -PassThru -ErrorAction Stop
        if ($InstallProcess.ExitCode -ne 0) {
            throw "Instalador DBeaver retornou codigo $($InstallProcess.ExitCode)"
        }
    }
    if (!(Test-Path $DBeaverPath)) {
        throw "ERRO: DBeaver nao encontrado em $DBeaverPath. Informe -DBeaverInstallerPath com o executavel do instalador ou instale-o antes de executar este script."
    }
    Add-Content $LogFile "DBeaver detectado em: $DBeaverPath"
    
    # Passo 2: Validar que source existe
    Add-Content $LogFile "Validando disponibilidade do workspace-default..."
    if (!(Test-Path $WorkspaceSourceBase)) {
        throw "Workspace de origem NAO encontrado: $WorkspaceSourceBase"
    }
    Add-Content $LogFile "Workspace de origem acessivel."
    
    # Passo 3: Fechar DBeaver
    Add-Content $LogFile "Encerrando processos DBeaver (se abertos)..."
    Stop-Process -Name "dbeaver" -Force -ErrorAction Ignore
    Stop-Process -Name "javaw" -ErrorAction Ignore
    Start-Sleep -Seconds 2
    Add-Content $LogFile "Processos encerrados."
    
    # Passo 4: Criar diretório base DBeaverData
    Add-Content $LogFile "Criando estrutura de diretorios..."
    New-Item -Path $DBeaverDataPath -ItemType Directory -Force | Out-Null
    
    # Passo 5: Copiar Drivers (pasta completa)
    Add-Content $LogFile "Copiando drivers..."
    try {
        if (Test-Path $DriversSourcePath) {
            New-Item -Path $DriversDestPath -ItemType Directory -Force | Out-Null
            Copy-Item -Path "$DriversSourcePath\*" -Destination $DriversDestPath -Recurse -Force -ErrorAction Stop
            $DriversCount = (Get-ChildItem -Path $DriversDestPath -Recurse -File -Filter "*.jar" -ErrorAction SilentlyContinue | Measure-Object).Count
            Add-Content $LogFile "Drivers copiados com sucesso. JARs encontrados: $DriversCount"
        }
        else {
            Add-Content $LogFile "AVISO: Pasta drivers nao encontrada em origem."
        }
    }
    catch {
        throw "Erro ao copiar drivers: $($_.Exception.Message)"
    }
    
    # Passo 6: Copiar .metadata\.config
    Add-Content $LogFile "Copiando configuracoes .metadata..."
    try {
        if (Test-Path $MetadataSourcePath) {
            New-Item -Path $MetadataDestPath -ItemType Directory -Force | Out-Null
            Copy-Item -Path "$MetadataSourcePath\*" -Destination $MetadataDestPath -Recurse -Force -ErrorAction Stop
            Add-Content $LogFile ".metadata\.config copiado com sucesso."
        }
        else {
            Add-Content $LogFile "AVISO: Pasta .metadata\.config nao encontrada em origem."
        }
    }
    catch {
        throw "Erro ao copiar .metadata\.config: $($_.Exception.Message)"
    }
    
    # Passo 7: Copiar General\.dbeaver
    Add-Content $LogFile "Copiando configuracoes General\.dbeaver..."
    try {
        if (Test-Path $GeneralSourcePath) {
            New-Item -Path $GeneralDestPath -ItemType Directory -Force | Out-Null
            Copy-Item -Path "$GeneralSourcePath\*" -Destination $GeneralDestPath -Recurse -Force -ErrorAction Stop
            Add-Content $LogFile "General\.dbeaver copiado com sucesso."
        }
        else {
            Add-Content $LogFile "AVISO: Pasta General\.dbeaver nao encontrada em origem."
        }
    }
    catch {
        throw "Erro ao copiar General\.dbeaver: $($_.Exception.Message)"
    }
    
    # Passo 8: Validar arquivos-chave
    Add-Content $LogFile "Validando arquivos-chave..."
    $DriversXml = "$MetadataDestPath\drivers.xml"
    $DataSourcesJson = "$GeneralDestPath\data-sources.json"
    $JarsPresentes = (Get-ChildItem -Path $DriversDestPath -Recurse -File -Filter "*.jar" -ErrorAction SilentlyContinue | Measure-Object).Count
    
    $ValidacaoOK = $true
    
    if (Test-Path $DriversXml) {
        Add-Content $LogFile "OK: drivers.xml encontrado."
    }
    else {
        Add-Content $LogFile "FALHA: drivers.xml NAO encontrado em $DriversXml"
        $ValidacaoOK = $false
    }
    
    if (Test-Path $DataSourcesJson) {
        Add-Content $LogFile "OK: data-sources.json encontrado."
    }
    else {
        Add-Content $LogFile "FALHA: data-sources.json NAO encontrado em $DataSourcesJson"
        $ValidacaoOK = $false
    }
    
    if ($JarsPresentes -gt 0) {
        Add-Content $LogFile "OK: $JarsPresentes drivers (JARs) encontrados."
    }
    else {
        Add-Content $LogFile "FALHA: Nenhum driver (JAR) encontrado em $DriversDestPath"
        $ValidacaoOK = $false
    }
    
    if (-not $ValidacaoOK) {
        throw "Validacao de arquivos-chave falhou. Verifique os logs acima."
    }
    
    Add-Content $LogFile "Injecao de workspace concluida com sucesso."
}
catch {
    $Status = "Falha"
    $Erro = $_.Exception.Message
    
    # Categorizar erro
    if ($Erro -match "Access Denied|Permission|Acesso negado") {
        $ErrorCategory = "PermissaoDenegada"
    }
    elseif ($Erro -match "not found|nao encontrado|caminho|Path") {
        $ErrorCategory = "CaminhoNaoEncontrado"
    }
    elseif ($Erro -match "timeout|time out|aguardar") {
        $ErrorCategory = "Timeout"
    }
    elseif ($Erro -match "espaco|disk|space") {
        $ErrorCategory = "EspacoDisco"
    }
    elseif ($Erro -match "DBeaver|install|instalacao") {
        $ErrorCategory = "FalhaInstalacao"
    }
    else {
        $ErrorCategory = "Outro"
    }

    Add-Content $LogFile "ERRO: $Erro"
    Add-Content $LogFile "Categoria do Erro: $ErrorCategory"
}

# Finalização
$Fim = Get-Date

$Duracao = [Math]::Round(
    ($Fim - $Inicio).TotalSeconds,
    2
)

# Informações finais do LOG
Add-Content $LogFile "Fim: $Fim"
Add-Content $LogFile "Duracao: $Duracao segundos"
Add-Content $LogFile "Status: $Status"
Add-Content $LogFile ""

# JSON padrão WAP
$Resultado = [PSCustomObject]@{
    Data                 = $Inicio.ToString("yyyy-MM-dd HH:mm:ss")
    Ferramenta           = "WAP-DBeaver-Install"
    Departamento         = $Department
    Status               = $Status
    DuracaoSegundos      = $Duracao
    Erro                 = $Erro
    TempoEconomizadoMins = 25
    AcessoRede           = $NetworkAccessible
}

# Nome do CSV
$NomeArquivo = "DBeaverInstall_{0}_{1}.csv" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss")
$ArquivoJson = Join-Path -Path $JsonPath -ChildPath $NomeArquivo
$ArquivoJsonBackup = Join-Path -Path $JsonPathBackup -ChildPath $NomeArquivo

# Exportação CSV com validação e retry
$JsonExportado = $false
$MaxTentativas = 3
$Tentativa = 0

while ($Tentativa -lt $MaxTentativas -and -not $JsonExportado) {
    $Tentativa++
    Add-Content $LogFile "Tentativa $Tentativa de $MaxTentativas para exportar CSV..."
    
    try {
        # Validar que o objeto pode ser serializado em CSV
        $CsvString = $Resultado | ConvertTo-Csv -NoTypeInformation -ErrorAction Stop
        Add-Content $LogFile "CSV serializacao: OK"
        
        # Tentar escrever no caminho de rede
        if (Test-Path $JsonPath) {
            $NetworkAccessible = $true
            Add-Content $LogFile "Caminho de rede acessivel. Escrevendo para: $ArquivoJson"
            $CsvString | Out-File -FilePath $ArquivoJson -Encoding UTF8 -Force -ErrorAction Stop
            
            # Validar que o arquivo foi criado
            Start-Sleep -Milliseconds 500
            if (Test-Path $ArquivoJson) {
                $FileSize = (Get-Item $ArquivoJson).Length
                Add-Content $LogFile "CSV gerado com sucesso em caminho de rede. Tamanho: $FileSize bytes"
                $JsonExportado = $true
            }
            else {
                Add-Content $LogFile "AVISO: Arquivo nao foi criado apos Out-File. Tentando backup..."
            }
        }
        else {
            Add-Content $LogFile "Caminho de rede nao acessivel. Usando backup local."
        }
        
        # Se nao foi exportado para rede, usar backup local
        if (-not $JsonExportado) {
            Add-Content $LogFile "Escrevendo CSV em backup local: $ArquivoJsonBackup"
            $CsvString | Out-File -FilePath $ArquivoJsonBackup -Encoding UTF8 -Force -ErrorAction Stop
            
            if (Test-Path $ArquivoJsonBackup) {
                Add-Content $LogFile "CSV exportado para backup local com sucesso."
                $JsonExportado = $true
            }
        }
    }
    catch {
        $ErroAtual = $_.Exception.Message
        Add-Content $LogFile "ERRO na tentativa $Tentativa - GERANDO CSV: $ErroAtual"
        
        if ($Tentativa -lt $MaxTentativas) {
            Add-Content $LogFile "Aguardando 2 segundos antes de retry..."
            Start-Sleep -Seconds 2
        }
    }
}

if (-not $JsonExportado) {
    Add-Content $LogFile "FALHA: CSV nao pode ser exportado apos $MaxTentativas tentativas."
    Add-Content $LogFile "AVISO: Telemetria CSV falhou, mas resultado operacional do instalador foi mantido."
}

if ($Status -eq "Sucesso") {
    exit 0
}
else {
    exit 1
}
