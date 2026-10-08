@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "LOG_CONVERTER=%~dp0DockerLog.js"
if not exist "%LOG_CONVERTER%" (
    echo ERRO: DockerLog.js nao encontrado junto ao instalador.
    exit /b 1
)
for /f "tokens=2 delims=:" %%C in ('chcp') do set "ORIGINAL_CODEPAGE=%%C"
chcp 65001 >nul
set "WSL_UTF8=1"

set "CSV_START_DATE=%DATE%"
set "CSV_START_TIME=%TIME%"
set "CSV_ERROR="
set "CSV_STATUS=Falha"
set "CSV_EXIT_CODE=1"
set "CSV_TOOL_NAME=WAP-Docker-Fase2"
set "CSV_TEST="
set "CHECK_ONLY="
if /i "%~1"=="--check-only" set "CHECK_ONLY=1"
if /i "%~1"=="--csv-test" (
    set "CSV_TEST=1"
    set "CSV_TOOL_NAME=WAP-Docker-Fase2-CSV-Test"
)
call :main "%~1"
set "CSV_EXIT_CODE=%errorlevel%"
if defined CHECK_ONLY goto exit_installer
if "%CSV_EXIT_CODE%"=="0" set "CSV_STATUS=Sucesso"
if not defined CSV_ERROR if not "%CSV_EXIT_CODE%"=="0" set "CSV_ERROR=Falha durante a execucao; consulte o log."
goto :finish

:main
set "LOGDIR=C:\Temp\WAP\Logs"
call :open_log
if not errorlevel 1 goto log_ready
set "LOGDIR=%TEMP%\WAP\Logs"
call :open_log
if errorlevel 1 (
    echo ERRO: nao foi possivel criar o log em "%LOG%".
    set "CSV_ERROR=Nao foi possivel criar o arquivo de log."
    exit /b 1
)
call :log "AVISO: sem acesso de gravacao em C:\Temp\WAP\Logs; usando log em TEMP."

:log_ready
echo Log desta execucao: "%LOG%"
call :log "Inicio do instalador Docker CMD."
>>"%LOG%" echo Script: %~f0
>>"%LOG%" echo Diretorio atual: %CD%
>>"%LOG%" echo USERNAME: %USERNAME%
>>"%LOG%" echo LOCALAPPDATA: %LOCALAPPDATA%
>>"%LOG%" echo Argumento: %~1
whoami.exe /user >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if errorlevel 1 exit /b 1
if defined CSV_TEST goto csv_test
goto install_flow

:csv_test
call :log "Teste CSV: executando ipconfig /flushdns sem iniciar ou alterar a distro Docker."
ipconfig.exe /flushdns >"%LOG_OUTPUT%" 2>&1
call :append_output OEM
if errorlevel 1 (
    set "CSV_EXIT_CODE=1"
    set "CSV_ERROR=ipconfig /flushdns retornou codigo de erro."
    call :log "ERRO: ipconfig /flushdns retornou codigo de erro."
) else (
    set "CSV_EXIT_CODE=0"
    set "CSV_ERROR="
    call :log "Teste ipconfig /flushdns concluido com sucesso."
)
exit /b %CSV_EXIT_CODE%

:install_flow

set "DISTRO=Ubuntu"
set "DEST=%LOCALAPPDATA%\WSL\%DISTRO%"
set "CACHE=%LOCALAPPDATA%\WAP\Docker"
set "FLAG=%CACHE%\.docker-installed-%USERNAME%-%DISTRO%"
set "LOCAL_PAYLOAD=C:\WAP\Docker"
set "NETWORK_PAYLOAD=coloque_seu_path_aqui"
set "ROOTFS_SOURCE=coloque_seu_path_aqui"
set "CHECK_ONLY="
if /i "%~1"=="--check-only" set "CHECK_ONLY=1"
if not defined CHECK_ONLY if not "%~1"=="" set "ROOTFS_SOURCE=%~1"
for %%I in ("%~dp0..\Util") do set "PACKAGE_PAYLOAD=%%~fI"

set "CURRENT_SID="
for /f "tokens=2 delims=," %%S in ('whoami.exe /user /fo csv /nh 2^>nul') do set "CURRENT_SID=%%~S"
if not defined CURRENT_SID (
    call :log "ERRO: nao foi possivel identificar a conta de execucao."
    exit /b 1
)
if "%CURRENT_SID%"=="S-1-5-18" (
    call :log "ERRO: SCCM iniciou como SYSTEM. Configure Install for user e usuario logado."
    exit /b 1
)
if not defined LOCALAPPDATA (
    call :log "ERRO: perfil do usuario indisponivel."
    exit /b 1
)

set "WSL=%SystemRoot%\System32\wsl.exe"
if exist "%SystemRoot%\Sysnative\wsl.exe" set "WSL=%SystemRoot%\Sysnative\wsl.exe"
if not exist "%WSL%" (
    call :log "ERRO: wsl.exe nao encontrado em System32/Sysnative. Verifique a instalacao do WSL."
    exit /b 1
)

call :log "Verificando runtime WSL antes de acessar o payload Docker."
"%WSL%" --version >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if not "%errorlevel%"=="0" (
    call :log "ERRO: runtime WSL ausente ou invalido. Instale/repare WSL e reinicie a maquina."
    exit /b 1
)
"%WSL%" --status >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if not "%errorlevel%"=="0" (
    call :log "ERRO: WSL indisponivel. Verifique instalacao e reboot pendente."
    exit /b 1
)
"%WSL%" -l -q >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if not "%errorlevel%"=="0" (
    call :log "ERRO: WSL nao conseguiu consultar as distribuicoes."
    exit /b 1
)
if defined CHECK_ONLY (
    call :log "CHECK-ONLY OK: contexto de usuario e runtime WSL disponiveis. Nenhuma distro foi importada ou alterada."
    call :log "Util do pacote: %PACKAGE_PAYLOAD%"
    call :log "Util de rede: %NETWORK_PAYLOAD%"
    call :log "Imagem de rede: %ROOTFS_SOURCE%"
    exit /b 0
)
if not exist "%CACHE%" mkdir "%CACHE%" 2>nul
if not exist "%CACHE%" (
    call :log "ERRO: nao foi possivel criar o cache do usuario."
    exit /b 1
)
call :registration
if not defined DISTRO_KEY goto prepare
call :validate
if errorlevel 1 exit /b 1
if not exist "%FLAG%" goto prepare
"%WSL%" -d %DISTRO% -u root --exec /usr/bin/test -f /etc/systemd/resolved.conf.d/wap-dns.conf >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if not "%errorlevel%"=="0" goto prepare
call :log "Instalacao existente validada: WSL2, systemd, Docker e Compose funcionais; DNS configurado."
exit /b 0

:prepare
if exist "%FLAG%" del /q "%FLAG%" 2>nul

set "FIRST=%PACKAGE_PAYLOAD%\firstrun-user.sh"
if not exist "%FIRST%" set "FIRST=%NETWORK_PAYLOAD%\firstrun-user.sh"
if not exist "%FIRST%" set "FIRST=%LOCAL_PAYLOAD%\firstrun-user.sh"
if not exist "%FIRST%" (
    call :log "ERRO: firstrun-user.sh nao encontrado no cache, pacote ou rede."
    exit /b 1
)

if defined DISTRO_KEY goto inject

:import
set "ROOTFS=%CACHE%\ubuntu-wap.wsl"
if exist "%ROOTFS%" for %%I in ("%ROOTFS%") do if not "%%~zI"=="0" goto import_distro
set "ROOTFS=%LOCAL_PAYLOAD%\ubuntu-wap.wsl"
if exist "%ROOTFS%" for %%I in ("%ROOTFS%") do if not "%%~zI"=="0" goto import_distro
set "SOURCE=%PACKAGE_PAYLOAD%\ubuntu-wap.wsl"
if not exist "%SOURCE%" set "SOURCE=%NETWORK_PAYLOAD%\ubuntu-wap.wsl"
if not exist "%SOURCE%" set "SOURCE=%ROOTFS_SOURCE%"
if not exist "%SOURCE%" (
    call :log "ERRO: ubuntu-wap.wsl nao encontrado no cache, pacote ou rede."
    exit /b 1
)
for %%I in ("%SOURCE%") do set "SOURCE_SIZE=%%~zI"
if "%SOURCE_SIZE%"=="0" (
    call :log "ERRO: imagem de origem vazia."
    exit /b 1
)
call :log "Copiando imagem para o cache do usuario."
copy /b /y "%SOURCE%" "%CACHE%\ubuntu-wap.wsl.part" >>"%LOG%" 2>&1
if errorlevel 1 (
    del /q "%CACHE%\ubuntu-wap.wsl.part" 2>nul
    call :log "ERRO: falha ao copiar a imagem WSL."
    exit /b 1
)
for %%I in ("%CACHE%\ubuntu-wap.wsl.part") do set "COPIED_SIZE=%%~zI"
if not "%COPIED_SIZE%"=="%SOURCE_SIZE%" (
    del /q "%CACHE%\ubuntu-wap.wsl.part" 2>nul
    call :log "ERRO: tamanho da copia difere da imagem de origem."
    exit /b 1
)
move /y "%CACHE%\ubuntu-wap.wsl.part" "%CACHE%\ubuntu-wap.wsl" >>"%LOG%" 2>&1
if errorlevel 1 (
    call :log "ERRO: falha ao finalizar o cache da imagem WSL."
    exit /b 1
)
set "ROOTFS=%CACHE%\ubuntu-wap.wsl"

:import_distro
if not exist "%LOCALAPPDATA%\WSL" mkdir "%LOCALAPPDATA%\WSL" 2>nul
call :log "Importando %DISTRO% em %DEST%."
"%WSL%" --import %DISTRO% "%DEST%" "%ROOTFS%" --version 2 >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if not "%errorlevel%"=="0" (
    call :log "ERRO: falha no wsl --import; veja o log."
    exit /b 1
)
call :registration
call :validate
if errorlevel 1 exit /b 1

:inject
call :log "Instalando first-run na distro."
"%WSL%" -d %DISTRO% -u root --exec /bin/sh -c "tr -d '\r' > /etc/profile.d/00-wap-firstrun.sh && bash -n /etc/profile.d/00-wap-firstrun.sh && chmod +x /etc/profile.d/00-wap-firstrun.sh && bash /etc/profile.d/00-wap-firstrun.sh --configure-network" <"%FIRST%" >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if not "%errorlevel%"=="0" (
    call :log "ERRO: falha ao instalar first-run ou configurar DNS; veja o log."
    exit /b 1
)
"%WSL%" --terminate %DISTRO% >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if not "%errorlevel%"=="0" (
    call :log "ERRO: falha ao encerrar a distro; veja o log."
    exit /b 1
)
if not exist "%CACHE%" mkdir "%CACHE%" 2>nul
if not exist "%CACHE%" (
    call :log "ERRO: nao foi possivel criar o cache do usuario para a flag."
    exit /b 1
)
type nul >"%FLAG%"
if errorlevel 1 (
    call :log "ERRO: nao foi possivel gravar a flag de conclusao."
    exit /b 1
)
call :log "OK: Docker validado. Configuracao do usuario Linux pendente do primeiro acesso interativo."
exit /b 0

:finish
call :time_to_centiseconds "%CSV_START_TIME%" CSV_START_CENTISECONDS
call :time_to_centiseconds "%TIME%" CSV_END_CENTISECONDS
set /a CSV_DURATION_CENTISECONDS=CSV_END_CENTISECONDS-CSV_START_CENTISECONDS
if %CSV_DURATION_CENTISECONDS% LSS 0 set /a CSV_DURATION_CENTISECONDS+=8640000
set /a CSV_DURATION_WHOLE=CSV_DURATION_CENTISECONDS/100
set /a CSV_DURATION_FRACTION=CSV_DURATION_CENTISECONDS %% 100
if %CSV_DURATION_FRACTION% LSS 10 set "CSV_DURATION_FRACTION=0%CSV_DURATION_FRACTION%"
set "CSV_DURATION_SECONDS=%CSV_DURATION_WHOLE%.%CSV_DURATION_FRACTION%"
call :export_csv

:exit_installer
if defined LOG_OUTPUT if exist "%LOG_OUTPUT%" del /q "%LOG_OUTPUT%" 2>nul
if defined ORIGINAL_CODEPAGE chcp %ORIGINAL_CODEPAGE% >nul
exit /b %CSV_EXIT_CODE%

:registration
set "DISTRO_KEY="
for /f "delims=" %%K in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Lxss" 2^>nul ^| findstr /b "HKEY_"') do call :match_distro "%%K"
exit /b 0

:match_distro
for /f "tokens=1,2,*" %%N in ('reg.exe query "%~1" /v DistributionName 2^>nul') do if /i "%%N"=="DistributionName" if /i "%%P"=="%DISTRO%" set "DISTRO_KEY=%~1"
exit /b 0

:validate
set "DISTRO_VERSION="
if not defined DISTRO_KEY goto invalid_distro
for /f "tokens=3" %%V in ('reg.exe query "%DISTRO_KEY%" /v Version 2^>nul') do set "DISTRO_VERSION=%%V"
if not "%DISTRO_VERSION%"=="0x2" goto invalid_distro
call :log "Validando distro [%DISTRO%] via [%WSL%]; registro [%DISTRO_KEY%]."
"%WSL%" -d %DISTRO% -u root --exec /bin/true >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if not "%errorlevel%"=="0" (
    call :log "ERRO: a distro registrada nao iniciou. Consulte a saida WSL no log."
    exit /b 1
)
"%WSL%" -d %DISTRO% -u root --exec /bin/sh -c "test -d /run/systemd/system && command -v docker && docker --version && docker compose version && systemctl enable --now docker && docker info >/dev/null" >"%LOG_OUTPUT%" 2>&1
call :append_output UTF-8
if not "%errorlevel%"=="0" (
    if exist "%FLAG%" del /q "%FLAG%" 2>nul
    call :log "ERRO: Ubuntu nao iniciou corretamente ou systemd/Docker/Compose falhou. Nao sera reimportado automaticamente."
    exit /b 1
)
exit /b 0

:invalid_distro
if exist "%FLAG%" del /q "%FLAG%" 2>nul
call :log "ERRO: distro nao registrada como WSL2. Nenhuma conversao automatica sera realizada."
exit /b 1

:open_log
if not exist "%LOGDIR%" mkdir "%LOGDIR%" 2>nul
set "LOG=%LOGDIR%\WAP_DockerInstall.log"
set "LOG_OUTPUT=%TEMP%\WAP_DockerOutput_%RANDOM%_%RANDOM%.tmp"
if exist "%LOG%" (
    findstr /b /c:"WAP_LOG_ENCODING=UTF-8" "%LOG%" >nul 2>&1
    if errorlevel 1 (
        move "%LOG%" "%LOGDIR%\WAP_DockerInstall_legacy_%RANDOM%_%RANDOM%.log" >nul 2>&1
        if errorlevel 1 exit /b 1
    )
)
if not exist "%LOG%" (
    2>nul >"%LOG%" echo WAP_LOG_ENCODING=UTF-8
    if errorlevel 1 exit /b 1
)
2>nul >>"%LOG%" echo ============================================================
if errorlevel 1 exit /b 1
exit /b 0

:append_output
set "COMMAND_EXIT_CODE=%errorlevel%"
cscript.exe //nologo "%LOG_CONVERTER%" "%LOG_OUTPUT%" "%LOG%" "%~1"
if errorlevel 1 (
    call :log "ERRO: falha ao converter a saida do comando para UTF-8."
    exit /b 1
)
exit /b %COMMAND_EXIT_CODE%

:log
set "LOG_MESSAGE=%~1"
if /i "%LOG_MESSAGE:~0,5%"=="ERRO:" set "CSV_ERROR=%LOG_MESSAGE:~6%"
echo %date% %time% ^| %~1
>>"%LOG%" echo %date% %time% ^| %~1
exit /b 0

:time_to_centiseconds
set "RAW_TIME=%~1"
set "RAW_TIME=%RAW_TIME: =0%"
set /a "%~2=(1%RAW_TIME:~0,2%-100)*360000+(1%RAW_TIME:~3,2%-100)*6000+(1%RAW_TIME:~6,2%-100)*100+(1%RAW_TIME:~9,2%-100)"
exit /b 0

:export_csv
set "CSV_NETWORK="
if defined WAP_TELEMETRY_PATH set "CSV_NETWORK=%WAP_TELEMETRY_PATH%"
set "CSV_NETWORK_ACCESS=false"
set "CSV_FILE=DockerInstall_%COMPUTERNAME%_%RANDOM%_%RANDOM%.csv"
set "CSV_EXPORTED="

if defined LOCALAPPDATA (
    set "CSV_FALLBACK=%LOCALAPPDATA%\WAP\JsonBackup"
) else (
    set "CSV_FALLBACK=%TEMP%\WAP\JsonBackup"
)

if defined CSV_TEST (
    set "CSV_FALLBACK=%TEMP%\WAP\CSVTest"
    set "CSV_FILE=DockerInstall_CSVTest_%COMPUTERNAME%_%RANDOM%_%RANDOM%.csv"
    goto csv_fallback
)

if defined CSV_NETWORK if exist "%CSV_NETWORK%\" set "CSV_NETWORK_ACCESS=true"
if /i "%CSV_NETWORK_ACCESS%"=="true" (
    for /l %%A in (1,1,3) do (
        if not defined CSV_EXPORTED call :write_csv "%CSV_NETWORK%\%CSV_FILE%"
        if not errorlevel 1 set "CSV_EXPORTED=1"
        if not defined CSV_EXPORTED if %%A LSS 3 timeout /t 2 /nobreak >nul
    )
)

if defined CSV_EXPORTED (
    call :log "Telemetria CSV exportada para a rede: %CSV_NETWORK%\%CSV_FILE%"
    exit /b 0
)

:csv_fallback
if not exist "%CSV_FALLBACK%" mkdir "%CSV_FALLBACK%" 2>nul
for /l %%A in (1,1,3) do (
    if not defined CSV_EXPORTED call :write_csv "%CSV_FALLBACK%\%CSV_FILE%"
    if not errorlevel 1 set "CSV_EXPORTED=1"
    if not defined CSV_EXPORTED if %%A LSS 3 timeout /t 2 /nobreak >nul
)

if defined CSV_EXPORTED (
    call :log "AVISO: telemetria CSV salva no fallback local: %CSV_FALLBACK%\%CSV_FILE%"
    if defined CSV_TEST type "%CSV_FALLBACK%\%CSV_FILE%"
) else (
    call :log "AVISO: nao foi possivel exportar o CSV da telemetria."
)
exit /b 0

:write_csv
>"%~1" echo "Data","Ferramenta","Departamento","Status","DuracaoSegundos","Erro","TempoEconomizadoMins","AcessoRede"
if errorlevel 1 exit /b 1
>>"%~1" echo "%CSV_START_DATE% %CSV_START_TIME%","%CSV_TOOL_NAME%","Unknown","%CSV_STATUS%",%CSV_DURATION_SECONDS%,"%CSV_ERROR%",20,%CSV_NETWORK_ACCESS%
if errorlevel 1 exit /b 1
if not exist "%~1" exit /b 1
exit /b 0