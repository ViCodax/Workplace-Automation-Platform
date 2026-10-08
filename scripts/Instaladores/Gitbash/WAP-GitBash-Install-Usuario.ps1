# Instala Git for Windows no contexto do usuario atual. Requer internet.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$LogPath = 'C:\Temp\WAP\Logs'
$LogFile = Join-Path $LogPath 'WAP_GitBashInstall.log'
New-Item -Path $LogPath -ItemType Directory -Force | Out-Null

function Write-Log([string]$Message) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Message" | Add-Content $LogFile
}

try {
    if (Get-Command git.exe -ErrorAction SilentlyContinue) {
        Write-Log "Git ja esta instalado: $(& git --version)"
        exit 0
    }

    $Winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($Winget) {
        Write-Log 'Instalando Git.Git pelo WinGet.'
        & $Winget.Source install --id Git.Git --exact --source winget --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) { exit 0 }
        Write-Log "WinGet retornou codigo $LASTEXITCODE; tentando a fonte oficial."
    }

    $Release = Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' -Headers @{ 'User-Agent' = 'WAP-GitBash-Install' }
    $Asset = $Release.assets | Where-Object { $_.name -match '64-bit\.exe$' } | Select-Object -First 1
    if (-not $Asset) { throw 'Nenhum instalador Git for Windows 64-bit foi localizado na release atual.' }
    $Installer = Join-Path $env:TEMP 'Git-Install.exe'
    Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Installer
    $Process = Start-Process -FilePath $Installer -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-' -Wait -PassThru
    if ($Process.ExitCode -ne 0) { throw "O instalador oficial retornou codigo $($Process.ExitCode)." }
    Remove-Item $Installer -Force -ErrorAction SilentlyContinue
    exit 0
}
catch {
    Write-Log "ERRO: $($_.Exception.Message)"
    exit 1
}