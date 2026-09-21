# Importa a distribuicao WSL para o usuario que fizer logon. Executada pela Fase 1.
[CmdletBinding()]
param(
    [string]$DistroName = 'Ubuntu-Docker',
    [string]$RootfsFileName = 'ubuntu-docker.wsl'
)

$ErrorActionPreference = 'Stop'
$Base = 'C:\WAP\Docker'
$LogPath = 'C:\Temp\WAP\Logs'
$LogFile = Join-Path $LogPath 'WAP_DockerInstall.log'
$Rootfs = Join-Path $Base $RootfsFileName
$Destination = Join-Path $env:LOCALAPPDATA "WSL\$DistroName"
New-Item -ItemType Directory -Force -Path $Destination, $LogPath | Out-Null

function Write-Log([string]$Message) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Message" | Add-Content $LogFile
}

try {
    if (-not (Test-Path $Rootfs -PathType Leaf)) { throw "Imagem WSL nao encontrada: $Rootfs" }
    $Registered = @(& wsl.exe --list --quiet 2>$null) | ForEach-Object { $_.ToString().Trim() }
    if ($Registered -notcontains $DistroName) {
        & wsl.exe --import $DistroName $Destination $Rootfs --version 2
        if ($LASTEXITCODE -ne 0) { throw "wsl --import falhou. Codigo: $LASTEXITCODE" }
    }

    $FirstRunScript = Join-Path $Base 'firstrun-user.sh'
    if (-not (Test-Path $FirstRunScript -PathType Leaf)) { throw "Script de primeiro acesso nao encontrado: $FirstRunScript" }
    Get-Content $FirstRunScript -Raw | & wsl.exe -d $DistroName -u root -- bash -c 'cat > /etc/profile.d/00-wap-firstrun.sh && chmod +x /etc/profile.d/00-wap-firstrun.sh'
    if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar o script de primeiro acesso. Codigo: $LASTEXITCODE" }
    & wsl.exe --terminate $DistroName
    Unregister-ScheduledTask -TaskName 'WAP-Docker-Fase2' -TaskPath '\WAP\' -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    Write-Log "Fase 2 concluida para $env:USERNAME. Abra '$DistroName' para criar o usuario Linux."
    exit 0
}
catch {
    Write-Log "ERRO: $($_.Exception.Message)"
    exit 1
}