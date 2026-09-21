# ==========================================
# WAP - Reparo de Impressora (Maquina)
# Execute como administrador. Informe o driver do seu ambiente.
# ==========================================

param(
    [Parameter(Mandatory = $true)]
    [string]$DriverName,

    [Parameter(Mandatory = $true)]
    [string]$DriverInfPath,

    [string]$TelemetryPath = ""
)

$LogPath = "C:\Temp\WAP\Logs"
$LogFile = Join-Path $LogPath "WAP_ReparoImpressora.log"
$LocalTelemetryPath = "C:\Temp\WAP\JsonBackup"
$Inicio = Get-Date
$Status = "Sucesso"
$Erro = ""

New-Item -Path $LogPath, $LocalTelemetryPath -ItemType Directory -Force | Out-Null

try {
    if (-not (Test-Path $DriverInfPath -PathType Leaf)) {
        throw "Driver INF nao encontrado: $DriverInfPath. Informe o caminho do INF do driver da impressora."
    }

    Add-Content $LogFile "Instalando driver: $DriverName"
    $PrintUiPath = Join-Path $env:SystemRoot "System32\rundll32.exe"
    & $PrintUiPath "printui.dll,PrintUIEntry" "/ia" "/m" $DriverName "/f" $DriverInfPath
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao instalar o driver. Codigo: $LASTEXITCODE"
    }

    Add-Content $LogFile "Parando o Spooler e limpando a fila..."
    Stop-Service -Name Spooler -Force -ErrorAction Stop
    $SpoolPath = Join-Path $env:SystemRoot "System32\spool\PRINTERS"
    Get-ChildItem -Path $SpoolPath -File -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Set-Service -Name Spooler -StartupType Automatic -ErrorAction Stop
    Start-Service -Name Spooler -ErrorAction Stop
    if ((Get-Service -Name Spooler).Status -ne 'Running') {
        throw "O servico Spooler nao iniciou apos o reparo."
    }
}
catch {
    $Status = "Falha"
    $Erro = $_.Exception.Message
    Add-Content $LogFile "ERRO: $Erro"
}

$Fim = Get-Date
$Resultado = [PSCustomObject]@{
    Data = $Inicio.ToString('yyyy-MM-dd HH:mm:ss')
    Ferramenta = 'WAP-ReparoImpressora'
    Status = $Status
    DuracaoSegundos = [Math]::Round(($Fim - $Inicio).TotalSeconds, 2)
    Erro = $Erro
}

$OutputPath = if ([string]::IsNullOrWhiteSpace($TelemetryPath)) { $LocalTelemetryPath } else { $TelemetryPath }
try {
    if (-not (Test-Path $OutputPath)) { New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null }
    $Resultado | Export-Csv -Path (Join-Path $OutputPath "ReparoImpressora_$env:COMPUTERNAME`_$(Get-Date -Format yyyyMMddHHmmss).csv") -NoTypeInformation -Encoding UTF8
}
catch {
    Add-Content $LogFile "AVISO: Nao foi possivel gravar a telemetria: $($_.Exception.Message)"
}

if ($Status -eq 'Sucesso') { exit 0 }
exit 1