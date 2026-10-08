<#
==================================================================================
 WAP - Workplace Automation Platform
 Instalador independente do WSL | Executa via SCCM no contexto SYSTEM
==================================================================================
 Objetivo:
   - Habilitar WSL + VirtualMachinePlatform (DISM funciona em SYSTEM, sem UAC)
   - Instalar o runtime/kernel do WSL via MSI (o MSI roda em SYSTEM;
     'wsl --install'/msixbundle exigem UAC interativo e falham no SCCM)
     - Nao instalar distribuicoes Linux nem preparar outro instalador
     - Devolver 3010 ao SCCM quando a maquina precisar reiniciar
     - MSI: colocar wsl.*.x64.msi junto ao script ou em Util; ou passar -MsiPath

 Deploy no SCCM (Application ou Package):
   Programa de instalacao:
     %windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File WSLInstall.ps1
   Executar como: System   |   Codigos de retorno: 0 e 3010 = sucesso (3010 = reboot)
==================================================================================
#>

[CmdletBinding()]
param(
    [string]$MsiPath = '',
    [string]$TelemetryPath = ''
)

# ---- 0) Re-lancar em 64-bit se cair em 32-bit (SysWOW64) ----
if ([IntPtr]::Size -eq 4 -and $env:PROCESSOR_ARCHITEW6432) {
    $ps64 = Join-Path $env:WINDIR "SysNative\WindowsPowerShell\v1.0\powershell.exe"
    # Falhar alto (nao mascarar como sucesso) se o relancamento nao puder ocorrer
    if ([string]::IsNullOrWhiteSpace($PSCommandPath) -or -not (Test-Path $ps64)) {
        Write-Error "Relancamento 64-bit impossivel: ps64='$ps64' PSCommandPath='$PSCommandPath'"
        exit 1
    }
    $RelaunchArguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($MsiPath) { $RelaunchArguments += @('-MsiPath', "`"$MsiPath`"") }
    if ($TelemetryPath) { $RelaunchArguments += @('-TelemetryPath', "`"$TelemetryPath`"") }
    $Relaunch = Start-Process -FilePath $ps64 -ArgumentList $RelaunchArguments -NoNewWindow -Wait -PassThru
    exit $Relaunch.ExitCode
}

$ErrorActionPreference = 'Stop'

# ---- 1) Configuração de caminhos e logs ----
$Base              = 'C:\WAP\WSL'
$LogPath           = "C:\Temp\WAP\Logs"
$JsonPathBackup    = "C:\Temp\WAP\JsonBackup"
$JsonPath          = if ([string]::IsNullOrWhiteSpace($TelemetryPath)) { $JsonPathBackup } else { $TelemetryPath }

New-Item -ItemType Directory -Force -Path $Base, $LogPath, $JsonPathBackup -ErrorAction Ignore | Out-Null

$LogFile           = Join-Path $LogPath 'PacoteWSL.log'
$Inicio            = Get-Date
$Status            = "Sucesso"
$Erro              = ""
$ErrorCategory     = "Nenhum"
$NetworkAccessible = $false
$RebootRequired    = $false

Add-Content $LogFile "=========================================="
Add-Content $LogFile "WAP - Instalacao independente do WSL (SYSTEM)"
Add-Content $LogFile "Bitness PS........: $([IntPtr]::Size * 8) bits"
Add-Content $LogFile "Identidade........: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Add-Content $LogFile "Computador........: $env:COMPUTERNAME"
Add-Content $LogFile "Origem do pacote..: $PSScriptRoot"
Add-Content $LogFile "=========================================="

$WapDirectoryInfo = [PSCustomObject]@{ DisplayName = 'SYSTEM'; Department = 'SYSTEM' }
$WapTargetUser = 'SYSTEM'
$WapTargetDomain = $null
try {
    $WapTargetUser = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName
}
catch {}
if ([string]::IsNullOrWhiteSpace($WapTargetUser)) {
    try {
        $Explorer = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" -ErrorAction Stop |
            Sort-Object CreationDate -Descending | Select-Object -First 1
        if ($Explorer) {
            $Owner = Invoke-CimMethod -InputObject $Explorer -MethodName GetOwner -ErrorAction Stop
            if ($Owner.User -and $Owner.Domain) { $WapTargetUser = '{0}\{1}' -f $Owner.Domain, $Owner.User }
        }
    }
    catch {}
}
if (-not [string]::IsNullOrWhiteSpace($WapTargetUser) -and $WapTargetUser -ne 'SYSTEM') {
    if ($WapTargetUser -match '^([^\\]+)\\') { $WapTargetDomain = $Matches[1] }
    Add-Content $LogFile "Usuario-alvo detectado: $WapTargetUser"
}
else {
    $WapTargetUser = 'SYSTEM'
    Add-Content $LogFile 'Nenhum usuario interativo detectado; telemetria permanecera como SYSTEM.'
}

function Get-WAP-DirectoryUserInfo {
    param([string]$TargetUser, [string]$TargetDomain)
    $Info = [PSCustomObject]@{ DisplayName = 'Unknown'; Department = 'Unknown' }
    if ([string]::IsNullOrWhiteSpace($TargetUser) -or $TargetUser -eq 'SYSTEM') { return $Info }
    if ($TargetUser -match '^([^\\]+)\\(.+)$') { if (-not $TargetDomain) { $TargetDomain = $Matches[1] }; $TargetUser = $Matches[2] }
    try { Import-Module ActiveDirectory -ErrorAction Stop; $Query = @{ Identity = $TargetUser; Properties = @('DisplayName', 'Department'); ErrorAction = 'Stop' }; if ($TargetDomain) { $Query.Server = (Get-ADDomain -Identity $TargetDomain -ErrorAction Stop).DNSRoot }; $ADUser = Get-ADUser @Query; if ($ADUser.DisplayName) { $Info.DisplayName = $ADUser.DisplayName }; if ($ADUser.Department) { $Info.Department = $ADUser.Department } }
    catch { Add-Content $LogFile "AVISO Get-ADUser: $($_.Exception.Message)" }
    if ($Info.DisplayName -eq 'Unknown' -or $Info.Department -eq 'Unknown') {
        $Entry = $null; $Searcher = $null
        try { $RootDSE = [ADSI]'LDAP://RootDSE'; $LDAPServer = [string]$RootDSE.Properties['dnsHostName'][0]; $BaseDN = [string]$RootDSE.Properties['defaultNamingContext'][0]; if (-not $LDAPServer -or -not $BaseDN) { throw 'RootDSE indisponivel.' }; $EscapedUser = $TargetUser.Replace('\', '\5c').Replace('*', '\2a').Replace('(', '\28').Replace(')', '\29').Replace([string][char]0, '\00'); Add-Type -AssemblyName System.DirectoryServices -ErrorAction Stop; $Entry = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$LDAPServer/$BaseDN"); $Searcher = New-Object System.DirectoryServices.DirectorySearcher; $Searcher.SearchRoot = $Entry; $Searcher.Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$EscapedUser))"; $Searcher.ServerTimeLimit = [TimeSpan]::FromSeconds(5); $Searcher.ClientTimeout = [TimeSpan]::FromSeconds(8); [void]$Searcher.PropertiesToLoad.Add('displayName'); [void]$Searcher.PropertiesToLoad.Add('department'); $Result = $Searcher.FindOne(); if (-not $Result) { throw 'Usuario nao encontrado.' }; if ($Info.DisplayName -eq 'Unknown' -and $Result.Properties['displayname'].Count) { $Info.DisplayName = [string]$Result.Properties['displayname'][0] }; if ($Info.Department -eq 'Unknown' -and $Result.Properties['department'].Count) { $Info.Department = [string]$Result.Properties['department'][0] } }
        catch { Add-Content $LogFile "AVISO DirectorySearcher: $($_.Exception.Message)" } finally { if ($Searcher) { $Searcher.Dispose() }; if ($Entry) { $Entry.Dispose() } }
    }
    if ($Info.DisplayName -eq 'Unknown' -or $Info.Department -eq 'Unknown') {
        $Connection = $null
        try { if (-not $LDAPServer -or -not $BaseDN) { $RootDSE = [ADSI]'LDAP://RootDSE'; $LDAPServer = [string]$RootDSE.Properties['dnsHostName'][0]; $BaseDN = [string]$RootDSE.Properties['defaultNamingContext'][0] }; if (-not $LDAPServer -or -not $BaseDN) { throw 'Controlador LDAP indisponivel.' }; $EscapedUser = $TargetUser.Replace('\', '\5c').Replace('*', '\2a').Replace('(', '\28').Replace(')', '\29').Replace([string][char]0, '\00'); Add-Type -AssemblyName System.DirectoryServices.Protocols -ErrorAction Stop; $Identifier = [System.DirectoryServices.Protocols.LdapDirectoryIdentifier]::new($LDAPServer, 389); $Connection = [System.DirectoryServices.Protocols.LdapConnection]::new($Identifier); $Connection.Timeout = [TimeSpan]::FromSeconds(8); $Connection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Negotiate; $Connection.SessionOptions.ProtocolVersion = 3; $Connection.SessionOptions.Signing = $true; $Connection.SessionOptions.Sealing = $true; $Connection.Bind(); $Request = [System.DirectoryServices.Protocols.SearchRequest]::new($BaseDN, "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$EscapedUser))", [System.DirectoryServices.Protocols.SearchScope]::Subtree, [string[]]@('displayName', 'department')); $Request.TimeLimit = [TimeSpan]::FromSeconds(5); $Response = [System.DirectoryServices.Protocols.SearchResponse]$Connection.SendRequest($Request, [TimeSpan]::FromSeconds(8)); if ($Response.Entries.Count -eq 0) { throw 'Usuario nao encontrado.' }; $Result = $Response.Entries[0]; if ($Info.DisplayName -eq 'Unknown' -and $Result.Attributes['displayName']) { $Info.DisplayName = [string]$Result.Attributes['displayName'][0] }; if ($Info.Department -eq 'Unknown' -and $Result.Attributes['department']) { $Info.Department = [string]$Result.Attributes['department'][0] } }
        catch { Add-Content $LogFile "AVISO LdapConnection: $($_.Exception.Message)" } finally { if ($Connection) { $Connection.Dispose() } }
    }
    return $Info
}

if ($WapTargetUser -ne 'SYSTEM') {
    $WapDirectoryInfo = Get-WAP-DirectoryUserInfo -TargetUser $WapTargetUser -TargetDomain $WapTargetDomain
}

$CompletedFlag    = Join-Path $Base '.wslinstall-completed'
function Test-WAP-WslRuntime {
    if (-not (Test-Path $WslExe -PathType Leaf)) { return $false }
    $ErrorActionPreference = 'Continue'
    $null = & $WslExe --version 2>&1
    return ($LASTEXITCODE -eq 0)
}

try {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Execute o instalador WSL como SYSTEM ou administrador.'
    }

    $WslExe = Join-Path $env:WINDIR 'System32\wsl.exe'
    $RuntimeInstalled = Test-WAP-WslRuntime
    if (-not $RuntimeInstalled) {
        if (-not $MsiPath) {
            $MsiCandidates = @($PSScriptRoot, (Join-Path $PSScriptRoot 'Util'))
            $Msi = Get-ChildItem -Path $MsiCandidates -Filter 'wsl.*.x64.msi' -File -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($Msi) { $MsiPath = $Msi.FullName }
        }
        if (-not $MsiPath -or -not (Test-Path $MsiPath -PathType Leaf)) {
            throw 'Runtime WSL ausente. Inclua wsl.*.x64.msi no pacote WSL ou informe -MsiPath.'
        }
        $MsiFile = Get-Item -LiteralPath $MsiPath
        if ($MsiFile.Length -le 0) { throw 'MSI do WSL vazio.' }
        $MsiPath = $MsiFile.FullName
    }

    Remove-Item $CompletedFlag -Force -ErrorAction SilentlyContinue
    foreach ($FeatureName in @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')) {
        $Feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
        Add-Content $LogFile "Recurso $FeatureName : $($Feature.State)"
        if ($Feature.State -eq 'Enabled') { continue }
        if ($Feature.State -eq 'EnablePending') {
            $RebootRequired = $true
            continue
        }
        $DismResult = Start-Process -FilePath 'dism.exe' -ArgumentList @('/online', '/enable-feature', "/featurename:$FeatureName", '/all', '/norestart') -Wait -PassThru -WindowStyle Hidden
        if ($DismResult.ExitCode -notin @(0, 3010)) {
            throw "DISM falhou ao habilitar $FeatureName. Codigo: $($DismResult.ExitCode)"
        }
        $RebootRequired = $true
        $Feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
        if ($Feature.State -notin @('Enabled', 'EnablePending')) {
            throw "Recurso $FeatureName nao foi habilitado: $($Feature.State)"
        }
    }

    if (-not $RuntimeInstalled) {
        $LocalMsi = Join-Path $Base (Split-Path $MsiPath -Leaf)
        if ([IO.Path]::GetFullPath($MsiPath) -ine [IO.Path]::GetFullPath($LocalMsi)) {
            Copy-Item -LiteralPath $MsiPath -Destination $LocalMsi -Force
        }
        $MsiLog = Join-Path $LogPath 'WSL-runtime-msi.log'
        $MsiResult = Start-Process msiexec.exe -ArgumentList "/i `"$LocalMsi`" /qn /norestart /L*v `"$MsiLog`"" -Wait -PassThru
        Add-Content $LogFile "Runtime WSL: MSI retornou $($MsiResult.ExitCode)"
        if ($MsiResult.ExitCode -notin @(0, 3010, 1641)) {
            throw "Instalacao do runtime WSL falhou. Codigo: $($MsiResult.ExitCode)"
        }
        $RebootRequired = $true
    }

    if ($RebootRequired) {
        Add-Content $LogFile 'Instalacao concluida; SCCM deve reiniciar a maquina (3010). Nenhuma distro foi instalada.'
        Write-Host 'WSL instalado. Reinicializacao necessaria pelo SCCM.'
    } else {
        if (-not (Test-WAP-WslRuntime)) { throw 'Runtime WSL nao passou na validacao --version.' }
        $PreviousErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $WslStatusOutput = & $WslExe --status 2>&1
            $WslStatusExitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $PreviousErrorActionPreference
        }
        Add-Content $LogFile "Consulta WSL --status: codigo $WslStatusExitCode"
        if ($WslStatusOutput) { Add-Content $LogFile ($WslStatusOutput | Out-String) }
        if ($WslStatusExitCode -ne 0) {
            Add-Content $LogFile 'AVISO: --status nao confirmou o estado neste contexto. Recursos e runtime foram validados; distribuicoes devem ser verificadas no contexto do usuario.'
        }
        New-Item -Path $CompletedFlag -ItemType File -Force | Out-Null
        Add-Content $LogFile 'Recursos e runtime WSL validados. Nenhuma distro foi instalada.'
        Write-Host 'Recursos e runtime WSL ja instalados e validados.'
    }
}
catch {
    Remove-Item $CompletedFlag -Force -ErrorAction SilentlyContinue
    $Status = "Falha"
    $Erro = $_.Exception.Message
    
    if ($Erro -match "Access Denied|Permission|Acesso negado") {
        $ErrorCategory = "PermissaoDenegada"
    }
    elseif ($Erro -match "not found|nao encontrado|Path") {
        $ErrorCategory = "CaminhoNaoEncontrado"
    }
    elseif ($Erro -match "WSL|VirtualMachine|DISM") {
        $ErrorCategory = "FalhaRecurso"
    }
    else {
        $ErrorCategory = "Outro"
    }

    Write-Warning "ERRO: $Erro"
    Add-Content $LogFile "ERRO: $Erro"
    Add-Content $LogFile "Categoria: $ErrorCategory"
}
# ---- Finalizacao e Telemetria ----
$Fim = Get-Date
$Duracao = [Math]::Round(($Fim - $Inicio).TotalSeconds, 2)

Add-Content $LogFile "Fim: $Fim"
Add-Content $LogFile "Duracao: $Duracao segundos"
Add-Content $LogFile "Status: $Status"
Add-Content $LogFile ""

# JSON padrão WAP
$Resultado = [PSCustomObject]@{
    Data                 = $Inicio.ToString("yyyy-MM-dd HH:mm:ss")
    Ferramenta           = "WAP-WSLInstall"
    Usuario              = $WapTargetUser
    NomeUsuario          = $WapDirectoryInfo.DisplayName
    Departamento         = $WapDirectoryInfo.Department
    Status               = $Status
    DuracaoSegundos      = $Duracao
    Erro                 = $Erro
    TempoEconomizadoMins = 30
    AcessoRede           = $false
}

# Exportação CSV com retry
$NomeArquivo = "WSLInstall_{0}_{1}.csv" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss")
$ArquivoJson = Join-Path -Path $JsonPath -ChildPath $NomeArquivo
$ArquivoJsonBackup = Join-Path -Path $JsonPathBackup -ChildPath $NomeArquivo

$JsonExportado = $false
$MaxTentativas = 3
$Tentativa = 0

while ($Tentativa -lt $MaxTentativas -and -not $JsonExportado) {
    $Tentativa++
    Add-Content $LogFile "Tentativa $Tentativa de $MaxTentativas para exportar CSV..."
    
    try {
        $NetworkAccessible = Test-Path $JsonPath
        $Resultado.AcessoRede = $NetworkAccessible
        $CsvString = $Resultado | ConvertTo-Csv -NoTypeInformation -ErrorAction Stop
        
        if ($NetworkAccessible) {
            $CsvString | Out-File -FilePath $ArquivoJson -Encoding UTF8 -Force -ErrorAction Stop
            Start-Sleep -Milliseconds 500
            
            if (Test-Path $ArquivoJson) {
                Add-Content $LogFile "CSV exportado para rede com sucesso."
                $JsonExportado = $true
            }
        }
        
        if (-not $JsonExportado) {
            $CsvString | Out-File -FilePath $ArquivoJsonBackup -Encoding UTF8 -Force -ErrorAction Stop
            if (Test-Path $ArquivoJsonBackup) {
                Add-Content $LogFile "CSV exportado para backup local com sucesso."
                $JsonExportado = $true
            }
        }
    }
    catch {
        Add-Content $LogFile "ERRO na tentativa $Tentativa - Exportando CSV: $($_.Exception.Message)"
        if ($Tentativa -lt $MaxTentativas) {
            Start-Sleep -Seconds 2
        }
    }
}

if ($Status -eq "Sucesso") {
    if ($RebootRequired) {
        exit 3010   # sucesso, reboot pendente do DISM
    }
    exit 0          # sucesso, recursos ja estavam habilitados
}
else {
    exit 1
}
