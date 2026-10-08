# Instala o Claude Code para o usuario atual. Requer internet e WinGet ou acesso a claude.ai.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$LogPath = 'C:\Temp\WAP\Logs'
$LogFile = Join-Path $LogPath 'WAP_ClaudeIIIInstall.log'
New-Item -Path $LogPath -ItemType Directory -Force | Out-Null

function Write-Log([string]$Message) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Message" | Add-Content $LogFile
}

try {
    $ExistingClaude = Get-Command claude.exe -ErrorAction SilentlyContinue
    if ($ExistingClaude) {
        Write-Log "Claude CLI ja esta disponivel: $(& $ExistingClaude.Source --version 2>&1)"
        exit 0
    }

    $Winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($Winget) {
        Write-Log 'Instalando Anthropic.ClaudeCode pelo WinGet.'
        & $Winget.Source install --id Anthropic.ClaudeCode --exact --source winget --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) { exit 0 }
        Write-Log "WinGet retornou codigo $LASTEXITCODE; tentando a fonte oficial."
    }

    $Installer = Join-Path $env:TEMP 'claude-install.cmd'
    Write-Log 'Baixando instalador oficial de https://claude.ai/install.cmd.'
    Invoke-WebRequest -Uri 'https://claude.ai/install.cmd' -OutFile $Installer
    $Process = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "`"$Installer`"" -Wait -PassThru
    if ($Process.ExitCode -ne 0) { throw "O instalador oficial retornou codigo $($Process.ExitCode)." }
    Remove-Item $Installer -Force -ErrorAction SilentlyContinue
    exit 0
}
catch {
    Write-Log "ERRO: $($_.Exception.Message)"
    exit 1
}