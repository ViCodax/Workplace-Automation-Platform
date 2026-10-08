# Use esta variante para deploy de maquina. Caso o WinGet esteja indisponivel sob SYSTEM,
# execute WAP-GitBash-Install-Usuario.ps1 no contexto do usuario.
[CmdletBinding()]
param()

$ScriptPath = Join-Path $PSScriptRoot 'WAP-GitBash-Install-Usuario.ps1'
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script de instalacao por usuario nao encontrado: $ScriptPath"
    exit 1
}

& $ScriptPath
exit $LASTEXITCODE