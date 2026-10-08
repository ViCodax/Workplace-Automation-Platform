<#
==================================================================================
 WAP - Workplace Automation Platform
 Instalador independente do Docker CE | Executado no contexto do usuario
==================================================================================
 A imagem base 'ubuntu-wap.wsl' JA vem pronta com:
   - Docker CE instalado
   - Certificado Cloudflare
   - /etc/wsl.conf (systemd + generateResolvConf=false)
   - /etc/resolv.conf (DNS corporativo opcional + 1.1.1.1)
   - SEM usuario (root only) -> OOBE dispara no 1o open

 Requer runtime WSL instalado e disponivel, independentemente da origem.
 Este instalador nao habilita recursos Windows nem instala o runtime WSL.
 Responsabilidades:
   1) Importar a distro NO PERFIL DO USUARIO (--version 2)
    2) Validar WSL2, systemd, Docker CE e Compose
    3) Injetar o first-run (OOBE user+senha) em /etc/profile.d
==================================================================================
#>

[CmdletBinding()]
param(
    [string]$DistroName = 'Ubuntu',
    [string]$RootfsFileName = 'ubuntu-wap.wsl',
    [string]$FirstRunFileName = 'firstrun-user.sh',
    [string]$BasePath = (Join-Path $env:LOCALAPPDATA 'WAP\Docker'),
    [string]$RootfsSourcePath = 'coloque_seu_path_aqui',
    [string]$TelemetryPath = ''
)

$ErrorActionPreference = 'Stop'

function Invoke-WAP-Wsl {
    param([string[]]$Arguments)
    $ErrorActionPreference = 'Continue'
    $CommandOutput = @(& $WslExe @Arguments 2>&1)
    $CommandExitCode = $LASTEXITCODE
    if ($CommandExitCode -ne 0) {
        throw "WSL falhou ($CommandExitCode): $($Arguments -join ' '). $($CommandOutput -join ' ')"
    }
    return $CommandOutput
}

try {
    if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem -or -not $env:LOCALAPPDATA) {
        throw 'Execute o instalador Docker no contexto do usuario, nunca como SYSTEM.'
    }
    $WslExe = Join-Path $env:WINDIR 'System32\wsl.exe'
    if ([IntPtr]::Size -eq 4 -and $env:PROCESSOR_ARCHITEW6432) {
        $WslExe = Join-Path $env:WINDIR 'Sysnative\wsl.exe'
    }
    if (-not (Test-Path $WslExe -PathType Leaf)) { throw 'wsl.exe nao encontrado.' }
    $null = Invoke-WAP-Wsl -Arguments @('--version')
    $null = Invoke-WAP-Wsl -Arguments @('--status')
} catch {
    Write-Warning "WSL indisponivel: $($_.Exception.Message). Instale/repare o WSL e reinicie a maquina antes de instalar Docker."
    exit 1
}

# ---- Configuração de caminhos e logs ----
$Base              = $BasePath
$Distro            = $DistroName
$Dest              = Join-Path $env:LOCALAPPDATA "WSL\$Distro"
$LogPath           = Join-Path $env:LOCALAPPDATA 'WAP\Logs'
$JsonPathBackup    = Join-Path $env:LOCALAPPDATA 'WAP\JsonBackup'
$JsonPath          = if ([string]::IsNullOrWhiteSpace($TelemetryPath)) { $JsonPathBackup } else { $TelemetryPath }

New-Item -ItemType Directory -Force -Path $Base, $LogPath, $JsonPathBackup | Out-Null

$LogFile           = Join-Path $LogPath 'WAP_DockerInstall.log'
$Inicio            = Get-Date
$Status            = "Sucesso"
$NetworkAccessible = $false
$Erro              = ""
$ErrorCategory     = "Nenhum"

Add-Content $LogFile "=========================================="
Add-Content $LogFile "WAP - Instalacao independente do Docker (USER); pre-check WSL aprovado"
Add-Content $LogFile "Usuario........: $env:USERNAME"
Add-Content $LogFile "Identidade......: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Add-Content $LogFile "Computador......: $env:COMPUTERNAME"
Add-Content $LogFile "Base do payload: $Base"
Add-Content $LogFile "=========================================="

# Locais possiveis do payload, em ordem de preferencia (cache local -> pasta do script -> repo -> rede)
$RepoUtilSource = $null
if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $RepoUtilSource = Join-Path (Split-Path $PSScriptRoot -Parent) 'Util'
}
$NetworkUtilSource  = 'coloque_seu_path_aqui'
$ArtifactCandidates = @($Base, $PSScriptRoot, $RepoUtilSource, $NetworkUtilSource) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

function Resolve-WAP-Artifact {
    param(
        [string[]]$Candidates,
        [string]$FileName
    )

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        $candidatePath = Join-Path $candidate $FileName
        if (Test-Path $candidatePath -PathType Leaf) {
            return $candidatePath
        }
    }

    return $null
}

# So copia para $Base quando o arquivo ainda nao esta la (evita recopiar payload de ~1.9GB a cada execucao)
function Ensure-WAP-Artifact {
    param(
        [string]$FileName,
        [string[]]$Candidates,
        [string]$SourcePath = ''
    )

    $destination = Join-Path $Base $FileName
    if ((Test-Path $destination -PathType Leaf) -and (Get-Item $destination).Length -gt 0) {
        Add-Content $LogFile "Arquivo do payload ja presente: $destination"
        return $destination
    }

    $source = Resolve-WAP-Artifact -Candidates $Candidates -FileName $FileName
    if (-not $source -and $SourcePath -and (Test-Path $SourcePath -PathType Leaf)) {
        $source = $SourcePath
    }
    if (-not $source) {
        return $null
    }

    $SourceLength = (Get-Item $source).Length
    if ($SourceLength -le 0) { throw "Arquivo de origem vazio: $source" }
    $StagingPath = "$destination.part"
    try {
        Copy-Item -LiteralPath $source -Destination $StagingPath -Force -ErrorAction Stop
        if ((Get-Item $StagingPath).Length -ne $SourceLength) { throw "Copia incompleta: $source" }
        Move-Item -LiteralPath $StagingPath -Destination $destination -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $StagingPath -Force -ErrorAction SilentlyContinue
        throw
    }
    Add-Content $LogFile "Arquivo do payload recuperado: $source -> $destination"
    return $destination
}

# ---- Funções auxiliares para detecção de usuário ----
function Get-WAP-ExtractedUser {
    param()
    $LoggedUser = $env:USERNAME
    if ([string]::IsNullOrWhiteSpace($LoggedUser) -or $LoggedUser -eq "Unknown") {
        return "Unknown"
    }

    if ($LoggedUser -like "*\*") {
        $User = $LoggedUser.Split('\')[-1]
    }
    else {
        $User = $LoggedUser
    }

    return $User
}

function ConvertFrom-WAP-WslDistroList {
    param([object[]]$DistroList)

    $DistroList | ForEach-Object {
        ($_.ToString() -replace "`0", '').Trim()
    } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

$User = Get-WAP-ExtractedUser
$LoggedUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$SafeUser = ($User -replace '[^a-zA-Z0-9._-]', '_')
$SafeDistro = ($Distro -replace '[^a-zA-Z0-9._-]', '_')
$SuccessFlag = Join-Path $Base ".docker-installed-$SafeUser-$SafeDistro"
$Department = "Unknown"
$DisplayName = "Unknown"

function Get-WAP-DirectoryUserInfo {
    param([string]$TargetUser, [string]$TargetDomain)
    $Info = [PSCustomObject]@{ DisplayName = 'Unknown'; Department = 'Unknown' }
    if ([string]::IsNullOrWhiteSpace($TargetUser) -or $TargetUser -eq 'Unknown') { return $Info }
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

function Test-WAP-Docker {
    $Registration = Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction Stop |
        Get-ItemProperty | Where-Object { $_.DistributionName -ieq $Distro }
    if (-not $Registration -or $Registration.Version -ne 2) {
        throw "A distro $Distro precisa estar registrada como WSL2. Nenhuma conversao automatica sera realizada."
    }
    $DockerOutput = Invoke-WAP-Wsl -Arguments @('-d', $Distro, '-u', 'root', '--exec', '/bin/sh', '-c', 'test -d /run/systemd/system && command -v docker && docker --version && docker compose version && systemctl enable --now docker && docker info >/dev/null')
    $DockerOutput | ForEach-Object { Add-Content $LogFile "Docker: $_" }
}

try {
    if ($User -and $User -ne "Unknown" -and $User -notlike "*$") {
        $DomainName = if ($LoggedUser -match '^([^\\]+)\\') { $Matches[1] } else { $null }
        $DirectoryInfo = Get-WAP-DirectoryUserInfo -TargetUser $User -TargetDomain $DomainName
        $DisplayName = $DirectoryInfo.DisplayName
        $Department = $DirectoryInfo.Department
    }
}
catch {}

try {
    $DistroList = @(Invoke-WAP-Wsl -Arguments @('-l', '-q'))
    $jaExiste = ConvertFrom-WAP-WslDistroList -DistroList $DistroList | Where-Object { $_ -ieq $Distro }
    if ((Test-Path $SuccessFlag) -and $jaExiste) {
        Test-WAP-Docker
        Add-Content $LogFile 'Instalacao existente validada: WSL2, systemd, Docker e Compose funcionais.'
        exit 0
    }
    Remove-Item $SuccessFlag -Force -ErrorAction SilentlyContinue

    # --- 0) Garante o script de first-run (sempre necessario, mesmo se a distro ja existir) ----
    $FirstRunScript = Ensure-WAP-Artifact -FileName $FirstRunFileName -Candidates $ArtifactCandidates
    if (-not $FirstRunScript) {
        throw "Script de primeiro acesso nao encontrado. Esperado: $FirstRunFileName em $($ArtifactCandidates -join ', ')"
    }

    # --- 1) Importa a distro NO PERFIL DO USUARIO --------------------------
    Write-Host "[1/2] Verificando distro $Distro..."
    Add-Content $LogFile "[1/2] Verificando se distro ja foi importada..."
    
    if (-not $jaExiste) {
        # O rootfs (~1.9GB) so precisa ser resolvido/copiado quando o import for realmente necessario
        $Rootfs = Ensure-WAP-Artifact -FileName $RootfsFileName -Candidates $ArtifactCandidates -SourcePath $RootfsSourcePath
        if (-not $Rootfs) {
            throw "Arquivo da imagem WSL nao encontrado. Esperado: $RootfsFileName em $($ArtifactCandidates -join ', ')"
        }

        Write-Host "[1/2] Importando $Distro para $Dest ..."
        Add-Content $LogFile "Importando $Distro do rootfs: $Rootfs"
        New-Item -ItemType Directory -Force -Path $Dest | Out-Null
        Invoke-WAP-Wsl -Arguments @('--import', $Distro, $Dest, $Rootfs, '--version', '2') | ForEach-Object {
            Add-Content $LogFile "WSL: $_"
        }
        Add-Content $LogFile "Distro importada com sucesso para: $Dest"
    } else {
        Write-Host "[1/2] $Distro ja registrado - pulando import."
        Add-Content $LogFile "Distro $Distro ja estava registrada - import pulado."
    }

    Test-WAP-Docker

    # --- 2) Injeta o first-run (OOBE user+senha) --------------------------
    Write-Host "[2/2] Instalando first-run (pede user+senha no 1o open) ..."
    Add-Content $LogFile "[2/2] Injetando script $FirstRunFileName..."

    if (Test-Path $FirstRunScript -PathType Leaf) {
        Add-Content $LogFile "Script OOBE encontrado: $FirstRunScript"
        $FirstRunText = (Get-Content $FirstRunScript -Raw) -replace "`r", ''
        $PreviousErrorAction = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $InjectOutput = @($FirstRunText |
            & $WslExe -d $Distro -u root --exec /bin/sh -c 'cat > /etc/profile.d/00-wap-firstrun.sh && bash -n /etc/profile.d/00-wap-firstrun.sh && chmod +x /etc/profile.d/00-wap-firstrun.sh' 2>&1)
        $WslInjectExitCode = $LASTEXITCODE
        $ErrorActionPreference = $PreviousErrorAction
        $InjectOutput | ForEach-Object { Add-Content $LogFile "OOBE: $_" }
        if ($WslInjectExitCode -ne 0) {
            throw "Falha ao injetar o script OOBE na distro. Codigo: $WslInjectExitCode"
        }
        Add-Content $LogFile "Script OOBE injetado com sucesso."
    } else {
        throw "Script OOBE nao encontrado em: $FirstRunScript"
    }

    # encerra a distro para deixar tudo pronto pro 1o open do usuario
    Write-Host "Encerrando distro para aplicar configuracoes..."
    $null = Invoke-WAP-Wsl -Arguments @('--terminate', $Distro)
    Add-Content $LogFile "Distro encerrada. Pronta para primeiro acesso do usuario."

    Write-Host "OK - Fase 2 concluida para $env:USERNAME."
    Add-Content $LogFile "OK - Fase 2 concluida com sucesso para o usuario $env:USERNAME"
    
    # Marcar como completado para este usuario
    New-Item -Path $SuccessFlag -ItemType File -Force | Out-Null
    Add-Content $LogFile "Flag de conclusao criado para $User. Proximos logons deste usuario pularao esta fase."

    # Esta versao e executada no contexto do usuario e nao depende de gatilho automatizado.
    # A flag por usuario ja evita execucao duplicada para o mesmo perfil.
}
catch {
    Remove-Item $SuccessFlag -Force -ErrorAction SilentlyContinue
    $Status = "Falha"
    $Erro = $_.Exception.Message
    
    if ($Erro -match "not found|nao encontrado|Path") {
        $ErrorCategory = "CaminhoNaoEncontrado"
    }
    elseif ($Erro -match "WSL|wsl.exe") {
        $ErrorCategory = "FalhaWSL"
    }
    elseif ($Erro -match "Permission|Acesso negado") {
        $ErrorCategory = "PermissaoDenegada"
    }
    else {
        $ErrorCategory = "Outro"
    }

    Write-Warning "ERRO: $Erro"
    Add-Content $LogFile "ERRO: $Erro"
    Add-Content $LogFile "Categoria: $ErrorCategory"
}

# ---- Finalizacao ----
$Fim = Get-Date
$Duracao = [Math]::Round(($Fim - $Inicio).TotalSeconds, 2)

Add-Content $LogFile "Fim: $Fim"
Add-Content $LogFile "Duracao: $Duracao segundos"
Add-Content $LogFile "Status: $Status"
Add-Content $LogFile ""

$Resultado = [PSCustomObject]@{
    Data                 = $Inicio.ToString("yyyy-MM-dd HH:mm:ss")
    Ferramenta           = "WAP-Docker-Fase2"
    Usuario              = $User
    NomeUsuario          = $DisplayName
    Departamento         = $Department
    Status               = $Status
    DuracaoSegundos      = $Duracao
    Erro                 = $Erro
    TempoEconomizadoMins = 20
    AcessoRede           = $false
}

$NomeArquivo = "DockerInstall_{0}_{1}.csv" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss")
$ArquivoJson = Join-Path -Path $JsonPath -ChildPath $NomeArquivo
$ArquivoJsonBackup = Join-Path -Path $JsonPathBackup -ChildPath $NomeArquivo

$JsonExportado = $false
$MaxTentativas = 3
$Tentativa = 0

while ($Tentativa -lt $MaxTentativas -and -not $JsonExportado) {
    $Tentativa++
    Add-Content $LogFile "Tentativa $Tentativa de $MaxTentativas para exportar CSV do Docker..."

    try {
        $NetworkAccessible = Test-Path $JsonPath
        $Resultado.AcessoRede = $NetworkAccessible
        $CsvString = $Resultado | ConvertTo-Csv -NoTypeInformation -ErrorAction Stop

        if ($NetworkAccessible) {
            $CsvString | Out-File -FilePath $ArquivoJson -Encoding UTF8 -Force -ErrorAction Stop
            if (Test-Path $ArquivoJson) {
                Add-Content $LogFile "CSV Docker exportado para rede com sucesso."
                $JsonExportado = $true
            }
        }

        if (-not $JsonExportado) {
            $CsvString | Out-File -FilePath $ArquivoJsonBackup -Encoding UTF8 -Force -ErrorAction Stop
            if (Test-Path $ArquivoJsonBackup) {
                Add-Content $LogFile "CSV Docker exportado para backup local com sucesso."
                $JsonExportado = $true
            }
        }
    }
    catch {
        Add-Content $LogFile "ERRO na tentativa $Tentativa - Exportando CSV do Docker: $($_.Exception.Message)"
        if ($Tentativa -lt $MaxTentativas) {
            Start-Sleep -Seconds 2
        }
    }
}

if ($Status -eq "Sucesso") {
    exit 0
}
else {
    exit 1
}
