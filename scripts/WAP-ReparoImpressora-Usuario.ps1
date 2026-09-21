# ==========================================
# WAP - Configuracao da Impressora (Usuario)
# Execute no contexto do usuario que deve receber a impressora.
# Informe o servidor e o compartilhamento da impressora do seu ambiente.
# ==========================================

param(
    [Parameter(Mandatory = $true)]
    [string]$PrinterServer,

    [Parameter(Mandatory = $true)]
    [string]$PrinterShare
)

$LogPath = "C:\Temp\WAP\Logs"
$LogFile = Join-Path $LogPath "WAP_ReparoImpressora.log"
$Inicio = Get-Date
$PrinterConnection = "\\$PrinterServer\$PrinterShare"

if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

try {
    Add-Content $LogFile "=========================================="
    Add-Content $LogFile "WAP - Configuracao da Impressora (Etapa Usuario)"
    Add-Content $LogFile "Inicio etapa usuario: $Inicio"
    Add-Content $LogFile "Usuario: $env:USERDOMAIN\$env:USERNAME"
    Add-Content $LogFile "Impressora: $PrinterConnection"

    if (-not (Get-Printer -Name $PrinterConnection -ErrorAction SilentlyContinue)) {
        Add-Content $LogFile "Mapeando impressora..."
        Add-Printer -ConnectionName $PrinterConnection -ErrorAction Stop
    }
    else {
        Add-Content $LogFile "Impressora ja estava mapeada."
    }

    Add-Content $LogFile "Definindo impressora como padrao..."
    $WshNetwork = New-Object -ComObject WScript.Network
    $WshNetwork.SetDefaultPrinter($PrinterConnection)

    $DefaultPrinter = Get-CimInstance Win32_Printer -ErrorAction Stop |
        Where-Object { $_.Name -eq $PrinterConnection -and $_.Default }
    if (-not $DefaultPrinter) {
        throw "Nao foi possivel confirmar a impressora mapeada: $PrinterConnection"
    }

    $Fim = Get-Date
    $Duracao = [Math]::Round(($Fim - $Inicio).TotalSeconds, 2)
    Add-Content $LogFile "Impressora mapeada e definida como padrao com sucesso."
    Add-Content $LogFile "Fim etapa usuario: $Fim | Duracao: $Duracao segundos | Status: Sucesso"
    exit 0
}
catch {
    $Fim = Get-Date
    $Duracao = [Math]::Round(($Fim - $Inicio).TotalSeconds, 2)
    Add-Content $LogFile "ERRO etapa usuario: $($_.Exception.Message)"
    Add-Content $LogFile "Fim etapa usuario: $Fim | Duracao: $Duracao segundos | Status: Falha"
    exit 1
}