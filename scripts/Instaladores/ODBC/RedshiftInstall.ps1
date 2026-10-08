# WAP PowerShell template for new standalone SCCM scripts.
# Replace every WAP_ placeholder and implement only the operation-specific section.
# Do not copy this over any deployed script without separate approval and homologation.

[CmdletBinding()]
param(
    [string]$TelemetryPath = ''
)

$ErrorActionPreference = 'Stop'

# ---- WAP metadata: set these values before creating a package ----
$WapToolName = 'WAP_RedshiftInstall'
$WapVersion = '1.0.0'
$WapCategory = 'Instalacao'
$WapSavedMinutes = 0
$WapLogFileName = 'WAP_RedshiftInstall.log'

# ---- Standard paths for standalone Windows PowerShell scripts ----
$WapLogDirectory = 'C:\Temp\WAP\Logs'
$WapTelemetryFallbackDirectory = 'C:\Temp\WAP\JsonBackup'
$WapTelemetryDirectory = if ([string]::IsNullOrWhiteSpace($TelemetryPath)) { $WapTelemetryFallbackDirectory } else { $TelemetryPath }
$WapLogFile = Join-Path $WapLogDirectory $WapLogFileName
$WapMsiPath = Join-Path $PSScriptRoot 'AmazonRedshiftODBC64-1.6.3.1008.msi'
$WapMsiLogFile = Join-Path $WapLogDirectory 'WAP_RedshiftInstall_MSI.log'
$WapOdbcDriverName = 'Amazon Redshift (x64)'

New-Item -ItemType Directory -Path $WapLogDirectory, $WapTelemetryFallbackDirectory -Force | Out-Null

function Write-WapLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $Prefix = switch ($Level) {
        'WARN' { 'AVISO: ' }
        'ERROR' { 'ERRO: ' }
        default { '' }
    }
    Add-Content -LiteralPath $WapLogFile -Encoding UTF8 -Value "$Prefix$Message"
}

function Get-WapErrorCategory {
    param([string]$Message)

    if ($Message -match 'Access is denied|Access Denied|Permission|Acesso negado|Permissao') {
        return 'PermissaoDenegada'
    }
    if ($Message -match 'cannot find|not found|does not exist|nao encontrado|inexistente|caminho') {
        return 'CaminhoNaoEncontrado'
    }
    if ($Message -match 'timeout|timed out|time-out|tempo limite') {
        return 'Timeout'
    }
    return 'Outro'
}

function Get-WapDirectoryUserInfo {
    param(
        [string]$TargetUser,
        [string]$TargetDomain
    )

    if ([string]::IsNullOrWhiteSpace($TargetUser) -or $TargetUser -eq 'Unknown') {
        return [PSCustomObject]@{ DisplayName = 'Unknown'; Department = 'Unknown' }
    }

    if ($TargetUser -match '^([^\\]+)\\(.+)$') {
        if (-not $TargetDomain) { $TargetDomain = $Matches[1] }
        $TargetUser = $Matches[2]
    }
    $Info = [PSCustomObject]@{ DisplayName = 'Unknown'; Department = 'Unknown' }
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $ADQuery = @{ Identity = $TargetUser; Properties = @('DisplayName', 'Department'); ErrorAction = 'Stop' }
        if ($TargetDomain) { $ADQuery.Server = (Get-ADDomain -Identity $TargetDomain -ErrorAction Stop).DNSRoot }
        $DirectoryUser = Get-ADUser @ADQuery
        if ($DirectoryUser.DisplayName) { $Info.DisplayName = $DirectoryUser.DisplayName }
        if ($DirectoryUser.Department) { $Info.Department = $DirectoryUser.Department }
    }
    catch {
        Write-WapLog -Level WARN -Message "Get-ADUser indisponivel para '$TargetUser': $($_.Exception.Message)"
    }

    if ($Info.DisplayName -eq 'Unknown' -or $Info.Department -eq 'Unknown') {
        $Entry = $null
        $Searcher = $null
        try {
            $RootDSE = [ADSI]'LDAP://RootDSE'
            $LDAPServer = [string]$RootDSE.Properties['dnsHostName'][0]
            $BaseDN = [string]$RootDSE.Properties['defaultNamingContext'][0]
            if (-not $LDAPServer -or -not $BaseDN) { throw 'RootDSE indisponivel.' }
            $EscapedUser = $TargetUser.Replace('\', '\5c').Replace('*', '\2a').Replace('(', '\28').Replace(')', '\29').Replace([string][char]0, '\00')
            Add-Type -AssemblyName System.DirectoryServices -ErrorAction Stop
            $Entry = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$LDAPServer/$BaseDN")
            $Searcher = New-Object System.DirectoryServices.DirectorySearcher
            $Searcher.SearchRoot = $Entry
            $Searcher.Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$EscapedUser))"
            $Searcher.ServerTimeLimit = [TimeSpan]::FromSeconds(5)
            $Searcher.ClientTimeout = [TimeSpan]::FromSeconds(8)
            [void]$Searcher.PropertiesToLoad.Add('displayName')
            [void]$Searcher.PropertiesToLoad.Add('department')
            $Result = $Searcher.FindOne()
            if (-not $Result) { throw 'Usuario nao encontrado.' }
            if ($Info.DisplayName -eq 'Unknown' -and $Result.Properties['displayname'].Count) { $Info.DisplayName = [string]$Result.Properties['displayname'][0] }
            if ($Info.Department -eq 'Unknown' -and $Result.Properties['department'].Count) { $Info.Department = [string]$Result.Properties['department'][0] }
        }
        catch { Write-WapLog -Level WARN -Message "DirectorySearcher falhou para '$TargetUser': $($_.Exception.Message)" }
        finally { if ($Searcher) { $Searcher.Dispose() }; if ($Entry) { $Entry.Dispose() } }
    }

    if ($Info.DisplayName -eq 'Unknown' -or $Info.Department -eq 'Unknown') {
        $Connection = $null
        try {
            if (-not $LDAPServer -or -not $BaseDN) { $RootDSE = [ADSI]'LDAP://RootDSE'; $LDAPServer = [string]$RootDSE.Properties['dnsHostName'][0]; $BaseDN = [string]$RootDSE.Properties['defaultNamingContext'][0] }
            if (-not $LDAPServer -or -not $BaseDN) { throw 'Controlador LDAP indisponivel.' }
            $EscapedUser = $TargetUser.Replace('\', '\5c').Replace('*', '\2a').Replace('(', '\28').Replace(')', '\29').Replace([string][char]0, '\00')
            Add-Type -AssemblyName System.DirectoryServices.Protocols -ErrorAction Stop
            $Identifier = [System.DirectoryServices.Protocols.LdapDirectoryIdentifier]::new($LDAPServer, 389)
            $Connection = [System.DirectoryServices.Protocols.LdapConnection]::new($Identifier)
            $Connection.Timeout = [TimeSpan]::FromSeconds(8)
            $Connection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Negotiate
            $Connection.SessionOptions.ProtocolVersion = 3
            $Connection.SessionOptions.Signing = $true
            $Connection.SessionOptions.Sealing = $true
            $Connection.Bind()
            $Request = [System.DirectoryServices.Protocols.SearchRequest]::new($BaseDN, "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$EscapedUser))", [System.DirectoryServices.Protocols.SearchScope]::Subtree, [string[]]@('displayName', 'department'))
            $Request.TimeLimit = [TimeSpan]::FromSeconds(5)
            $Response = [System.DirectoryServices.Protocols.SearchResponse]$Connection.SendRequest($Request, [TimeSpan]::FromSeconds(8))
            if ($Response.Entries.Count -eq 0) { throw 'Usuario nao encontrado.' }
            $Result = $Response.Entries[0]
            if ($Info.DisplayName -eq 'Unknown' -and $Result.Attributes['displayName']) { $Info.DisplayName = [string]$Result.Attributes['displayName'][0] }
            if ($Info.Department -eq 'Unknown' -and $Result.Attributes['department']) { $Info.Department = [string]$Result.Attributes['department'][0] }
        }
        catch { Write-WapLog -Level WARN -Message "LdapConnection falhou para '$TargetUser': $($_.Exception.Message)" }
        finally { if ($Connection) { $Connection.Dispose() } }
    }

    return $Info
}

function Test-WapRedshiftDriverInstalled {
    $WapRegistryBaseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
        [Microsoft.Win32.RegistryHive]::LocalMachine,
        [Microsoft.Win32.RegistryView]::Registry64
    )
    $WapOdbcDriversKey = $null
    $WapOdbcDriverKey = $null
    $WapUninstallKey = $null

    try {
        $WapUninstallKey = $WapRegistryBaseKey.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
        if ($WapUninstallKey) {
            foreach ($WapProductKeyName in $WapUninstallKey.GetSubKeyNames()) {
                $WapProductKey = $WapUninstallKey.OpenSubKey($WapProductKeyName)
                if (-not $WapProductKey) {
                    continue
                }

                try {
                    $WapProductName = [string]$WapProductKey.GetValue('DisplayName', '')
                    if ($WapProductName -match '^Amazon Redshift\b.*(ODBC|x64|64-bit|64 bit)' -and
                        $WapProductName -notmatch '(x86|32-bit|32 bit)' -and
                        $WapProductKey.GetValue('WindowsInstaller', 0) -eq 1) {
                        $WapProductVersion = [string]$WapProductKey.GetValue('DisplayVersion', '')
                        Write-WapLog "Pacote MSI Redshift ja cadastrado no registro de 64 bits.`r`nNome: $WapProductName`r`nVersao instalada: $WapProductVersion`r`nChave MSI: $WapProductKeyName"
                        return $true
                    }
                }
                finally {
                    $WapProductKey.Dispose()
                }
            }
        }

        $WapOdbcDriversKey = $WapRegistryBaseKey.OpenSubKey('SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers')
        if (-not $WapOdbcDriversKey -or $WapOdbcDriversKey.GetValue($WapOdbcDriverName, $null) -ne 'Installed') {
            return $false
        }

        $WapOdbcDriverKey = $WapRegistryBaseKey.OpenSubKey("SOFTWARE\ODBC\ODBCINST.INI\$WapOdbcDriverName")
        if (-not $WapOdbcDriverKey) {
            return $false
        }

        $WapDriverDll = [Environment]::ExpandEnvironmentVariables($WapOdbcDriverKey.GetValue('Driver', ''))
        return -not [string]::IsNullOrWhiteSpace($WapDriverDll) -and (Test-Path -LiteralPath $WapDriverDll -PathType Leaf)
    }
    finally {
        if ($WapUninstallKey) {
            $WapUninstallKey.Dispose()
        }
        if ($WapOdbcDriverKey) {
            $WapOdbcDriverKey.Dispose()
        }
        if ($WapOdbcDriversKey) {
            $WapOdbcDriversKey.Dispose()
        }
        $WapRegistryBaseKey.Dispose()
    }
}

$WapStartedAt = Get-Date
$WapStatus = 'Sucesso'
$WapError = ''
$WapErrorCategory = 'Nenhum'
$WapOperationRetryCount = 0
$WapExitCode = 0
$WapComputerName = $env:COMPUTERNAME
$WapTargetUser = 'Unknown'
$WapDisplayName = 'Unknown'
$WapDepartment = 'Unknown'
$WapTelemetryExported = $false

$WapIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $WapIdentity.IsSystem) {
    $WapTargetUser = $env:USERNAME
    $WapTargetDomain = if ($WapIdentity.Name -match '^([^\\]+)\\') { $Matches[1] } else { $env:USERDOMAIN }
    $WapDirectoryUser = Get-WapDirectoryUserInfo -TargetUser $WapTargetUser -TargetDomain $WapTargetDomain
    $WapDisplayName = $WapDirectoryUser.DisplayName
    $WapDepartment = $WapDirectoryUser.Department
}

Write-WapLog (@(
    ''
    '=========================================='
    'WAP - Instalacao do Amazon Redshift ODBC'
    "Inicio: $($WapStartedAt.ToString('yyyy-MM-dd HH:mm:ss'))"
    "Ferramenta: $WapToolName"
    "Versao do script: $WapVersion"
    "Categoria: $WapCategory"
    "Identidade: $($WapIdentity.Name)"
    "Usuario alvo: $WapTargetUser"
    "Computador: $WapComputerName"
    "Departamento: $WapDepartment"
    '=========================================='
) -join "`r`n")

try {
    if (Test-WapRedshiftDriverInstalled) {
        Write-WapLog 'Amazon Redshift x64 detectado pelo cadastro MSI ou pelo driver ODBC e sua DLL. Instalacao ignorada; nenhuma atualizacao ou reparo foi executado.'
    }
    else {
        if ([string]::IsNullOrWhiteSpace($PSScriptRoot) -or -not (Test-Path -LiteralPath $PSScriptRoot -PathType Container)) {
            throw "Pasta local do payload nao encontrada: $PSScriptRoot"
        }
        if (-not (Test-Path -LiteralPath $WapMsiPath -PathType Leaf)) {
            throw "MSI do Amazon Redshift ODBC nao encontrado no payload local: $WapMsiPath"
        }

        if ([IntPtr]::Size -eq 4 -and $env:PROCESSOR_ARCHITEW6432) {
            $WapMsiExecPath = Join-Path $env:WINDIR 'Sysnative\msiexec.exe'
        }
        else {
            $WapMsiExecPath = Join-Path $env:WINDIR 'System32\msiexec.exe'
        }
        if (-not (Test-Path -LiteralPath $WapMsiExecPath -PathType Leaf)) {
            throw "Windows Installer nao encontrado: $WapMsiExecPath"
        }

        Write-WapLog "Iniciando instalacao silenciosa do driver ODBC...`r`nMSI: $WapMsiPath"
        $WapMsiProcess = Start-Process -FilePath $WapMsiExecPath -ArgumentList @(
            '/i', "`"$WapMsiPath`"", '/qn', '/norestart', '/L*v', "`"$WapMsiLogFile`""
        ) -Wait -PassThru -ErrorAction Stop

        switch ($WapMsiProcess.ExitCode) {
            0 {
                Write-WapLog 'Instalacao do driver Amazon Redshift ODBC concluida.'
            }
            3010 {
                $WapExitCode = 3010
                Write-WapLog -Level WARN -Message 'Instalacao concluida; o Windows requer reinicializacao (codigo MSI 3010).'
            }
            1641 {
                $WapExitCode = 3010
                Write-WapLog -Level WARN -Message 'Instalacao concluida; o Windows indicou reinicializacao (codigo MSI 1641).'
            }
            default {
                throw "msiexec falhou com codigo $($WapMsiProcess.ExitCode). Consulte o log MSI: $WapMsiLogFile"
            }
        }
    }
}
catch {
    $WapStatus = 'Falha'
    $WapError = $_.Exception.Message
    $WapErrorCategory = Get-WapErrorCategory -Message $WapError
    $WapExitCode = 1
    Write-WapLog -Level ERROR -Message "Operacao falhou.`r`nCategoria do erro: $WapErrorCategory`r`nDetalhes: $WapError"
}

$WapFinishedAt = Get-Date
$WapDurationSeconds = [Math]::Round(($WapFinishedAt - $WapStartedAt).TotalSeconds, 2)

Write-WapLog (@(
    ''
    "Fim: $($WapFinishedAt.ToString('yyyy-MM-dd HH:mm:ss'))"
    "Duracao: $WapDurationSeconds segundos"
    "Status: $WapStatus"
    ''
    'Exportando telemetria CSV...'
) -join "`r`n")

$WapTelemetry = [PSCustomObject]@{
    Data                 = $WapStartedAt.ToString('yyyy-MM-dd HH:mm:ss')
    Ferramenta           = $WapToolName
    VersaoScript         = $WapVersion
    Categoria            = $WapCategory
    Usuario              = $WapTargetUser
    NomeUsuario          = $WapDisplayName
    Computador           = $WapComputerName
    Departamento         = $WapDepartment
    Status               = $WapStatus
    DuracaoSegundos      = $WapDurationSeconds
    TempoEconomizadoMins = $WapSavedMinutes
    Erro                 = $WapError
    CategoriaErro        = $WapErrorCategory
    TentativasRetry      = $WapOperationRetryCount
}

$WapSafeToolName = $WapToolName -replace '[<>:"/\\|?*]', '_'
$WapTimestamp = $WapStartedAt.ToString('yyyyMMdd_HHmmss_fff')
$WapCsvFileName = '{0}_{1}_{2}.csv' -f $WapSafeToolName, $WapComputerName, $WapTimestamp
$WapNetworkCsvPath = Join-Path $WapTelemetryDirectory $WapCsvFileName
$WapLocalCsvPath = Join-Path $WapTelemetryFallbackDirectory $WapCsvFileName

if (Test-Path -LiteralPath $WapTelemetryDirectory -PathType Container) {
    for ($WapExportAttempt = 1; $WapExportAttempt -le 3 -and -not $WapTelemetryExported; $WapExportAttempt++) {
        try {
            $WapTelemetry | Export-Csv -LiteralPath $WapNetworkCsvPath -NoTypeInformation -Encoding UTF8 -Force -ErrorAction Stop
            $WapTelemetryExported = Test-Path -LiteralPath $WapNetworkCsvPath -PathType Leaf
            if (-not $WapTelemetryExported) {
                throw 'O CSV nao foi encontrado depois da exportacao para a rede.'
            }
        }
        catch {
            Write-WapLog -Level WARN -Message "Exportacao CSV na rede falhou (tentativa $WapExportAttempt/3): $($_.Exception.Message)"
            if ($WapExportAttempt -lt 3) {
                Start-Sleep -Seconds 2
            }
        }
    }
}
else {
    Write-WapLog -Level WARN -Message "Destino central indisponivel: $WapTelemetryDirectory"
}

if (-not $WapTelemetryExported) {
    try {
        $WapTelemetry | Export-Csv -LiteralPath $WapLocalCsvPath -NoTypeInformation -Encoding UTF8 -Force -ErrorAction Stop
        $WapTelemetryExported = Test-Path -LiteralPath $WapLocalCsvPath -PathType Leaf
        if (-not $WapTelemetryExported) {
            throw 'O CSV nao foi encontrado depois da exportacao local.'
        }
        Write-WapLog -Level WARN -Message "Telemetria salva no fallback local: $WapLocalCsvPath"
    }
    catch {
        Write-WapLog -Level ERROR -Message "Falha ao salvar telemetria local: $($_.Exception.Message)"
    }
}
else {
    Write-WapLog "Telemetria CSV exportada para a rede: $WapNetworkCsvPath"
}

Write-WapLog "Telemetria exportada: $WapTelemetryExported`r`n==========================================`r`n"

# Telemetry delivery does not change the operation result. Log both outcomes;
# SCCM exit status represents the operation, not whether the metrics share is reachable.
exit $WapExitCode