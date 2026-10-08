@echo off
setlocal

set "WAP_LOG_DIR=C:\Temp\WAP\Logs"
if not exist "%WAP_LOG_DIR%\" mkdir "%WAP_LOG_DIR%" >nul 2>&1
if not exist "%WAP_LOG_DIR%\" set "WAP_LOG_DIR=%TEMP%\WAP\Logs"
if not exist "%WAP_LOG_DIR%\" mkdir "%WAP_LOG_DIR%" >nul 2>&1
if not exist "%WAP_LOG_DIR%\" (
	echo ERRO: Nao foi possivel criar uma pasta para o log.
	exit /b 1
)
set "WAP_LOG_FILE=%WAP_LOG_DIR%\WAP_RedshiftInstall_DSN.log"

set "WAP_REG_EXE=%SystemRoot%\System32\reg.exe"
if defined PROCESSOR_ARCHITEW6432 set "WAP_REG_EXE=%SystemRoot%\Sysnative\reg.exe"
if not exist "%WAP_REG_EXE%" (
	call :log "ERRO: reg.exe nao encontrado: %WAP_REG_EXE%"
	exit /b 1
)

call :log "Inicio da configuracao do DSN Redshift."

whoami /user /fo csv /nh | findstr /c:"S-1-5-18" >nul
if not errorlevel 1 (
	call :log "ERRO: O processo esta como SYSTEM. Execute este CMD no contexto do usuario pelo SCCM para gravar o DSN no HKCU correto."
	exit /b 1
)

if not exist "%~dp0redshift_dsn.reg" (
	call :log "ERRO: Arquivo nao encontrado: %~dp0redshift_dsn.reg"
	exit /b 1
)
if not exist "%~dp0redshift_list.reg" (
	call :log "ERRO: Arquivo nao encontrado: %~dp0redshift_list.reg"
	exit /b 1
)

"%WAP_REG_EXE%" query "HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers" /v "Amazon Redshift (x64)" >nul 2>&1
if errorlevel 1 (
	call :log "ERRO: Driver Amazon Redshift (x64) nao encontrado. Instale primeiro o MSI RedshiftInstall."
	exit /b 1
)

call :log "Importando configuracao do DSN no perfil do usuario atual."
"%WAP_REG_EXE%" import "%~dp0redshift_dsn.reg" >>"%WAP_LOG_FILE%" 2>&1
if errorlevel 1 (
	call :log "ERRO: Falha ao importar redshift_dsn.reg."
	exit /b 1
)

"%WAP_REG_EXE%" import "%~dp0redshift_list.reg" >>"%WAP_LOG_FILE%" 2>&1
if errorlevel 1 (
	call :log "ERRO: Falha ao importar redshift_list.reg."
	exit /b 1
)

call :log "Configuracao do DSN Redshift concluida com sucesso."
exit /b 0

:log
>>"%WAP_LOG_FILE%" echo [%date% %time%] %~1
echo [%date% %time%] %~1
exit /b 0