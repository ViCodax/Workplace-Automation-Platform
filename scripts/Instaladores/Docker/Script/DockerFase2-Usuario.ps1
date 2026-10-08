# ==== WAP - Docker Install (Usuario) ====
# Execucao separada e controlada pelo usuario, pelo SCCM user-targeted,
# pela GPO de logon ou por chamada manual.

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

$DockerScriptPath = Join-Path $PSScriptRoot 'DockerInstall.ps1'

if (-not (Test-Path $DockerScriptPath)) {
    throw "Instalador Docker nao encontrado: $DockerScriptPath"
}

if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
    throw 'O instalador Docker deve ser executado no contexto do usuario.'
}

& $DockerScriptPath @PSBoundParameters
exit $LASTEXITCODE
