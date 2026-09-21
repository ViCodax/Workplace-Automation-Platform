# Preparacao de maquina para Docker via WSL. Execute como administrador/SYSTEM.
# PayloadPath deve conter DockerFase2.ps1, firstrun-user.sh e uma imagem .wsl preparada.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PayloadPath,

    [string]$DistroName = 'Ubuntu-Docker',

    [string]$RootfsFileName = 'ubuntu-docker.wsl'
)

$ErrorActionPreference = 'Stop'
$Base = 'C:\WAP\Docker'
$LogPath = 'C:\Temp\WAP\Logs'
$LogFile = Join-Path $LogPath 'WAP_DockerInstall.log'
New-Item -ItemType Directory -Force -Path $Base, $LogPath | Out-Null

function Write-Log([string]$Message) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Message" | Add-Content $LogFile
}

try {
    if (-not (Test-Path $PayloadPath -PathType Container)) {
        throw "Pasta de payload nao encontrada: $PayloadPath. Cole aqui a pasta que contem os arquivos Docker."
    }

    foreach ($File in 'DockerFase2.ps1', 'firstrun-user.sh', $RootfsFileName) {
        $Source = Join-Path $PayloadPath $File
        if (-not (Test-Path $Source -PathType Leaf)) {
            throw "Arquivo obrigatorio nao encontrado no payload: $Source"
        }
        Copy-Item -Path $Source -Destination (Join-Path $Base $File) -Force
    }

    $WslMsi = Get-ChildItem -Path $PayloadPath -Filter 'wsl.*.x64.msi' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($WslMsi) { Copy-Item $WslMsi.FullName -Destination $Base -Force }

    foreach ($Feature in 'Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform') {
        $Result = Start-Process -FilePath dism.exe -ArgumentList '/online', '/enable-feature', "/featurename:$Feature", '/all', '/norestart' -Wait -PassThru -WindowStyle Hidden
        if ($Result.ExitCode -notin 0, 3010) { throw "DISM falhou ao habilitar $Feature. Codigo: $($Result.ExitCode)" }
    }

    $LocalWslMsi = Get-ChildItem -Path $Base -Filter 'wsl.*.x64.msi' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($LocalWslMsi) {
        $Result = Start-Process msiexec.exe -ArgumentList "/i `"$($LocalWslMsi.FullName)`" /qn /norestart" -Wait -PassThru
        if ($Result.ExitCode -notin 0, 3010, 1641) { throw "Instalacao do MSI WSL falhou. Codigo: $($Result.ExitCode)" }
    }

    $Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$Base\DockerFase2.ps1`" -DistroName `"$DistroName`" -RootfsFileName `"$RootfsFileName`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -GroupId 'S-1-5-32-545' -RunLevel Limited
    Register-ScheduledTask -TaskName 'WAP-Docker-Fase2' -TaskPath '\WAP\' -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force | Out-Null
    Write-Log 'Fase 1 concluida. Reinicie a maquina antes do proximo logon.'
    exit 3010
}
catch {
    Write-Log "ERRO: $($_.Exception.Message)"
    exit 1
}