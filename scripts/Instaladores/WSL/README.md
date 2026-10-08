# Instalador WSL

Habilita os recursos do Windows necessários e instala o runtime moderno do WSL via MSI. Não importa distribuição Linux, não instala Docker e não registra gatilhos de logon.

| Item | Valor |
|---|---|
| Script | `WSLInstall.ps1` |
| Contexto | Máquina (SYSTEM) |
| Privilégios | SYSTEM ou administrador |
| Reinicialização | Sim: retorna `3010` quando instala ou habilita algo |
| Economia estimada | 30 minutos por instalação bem-sucedida |

## Conteúdo do pacote

```text
WSL/
  WSLInstall.ps1
  wsl.<versao>.x64.msi   # fornecido pelo seu ambiente
```

O MSI oficial precisa ser incluído no pacote, ficar em `WSL/Util` ou ser indicado por `-MsiPath`. Não há download automático nem fallback para o WSL inbox: sem runtime válido e sem MSI, o instalador falha antes de alterar os recursos do Windows.

## Parâmetros

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `-MsiPath` | Não | Caminho do MSI do WSL. Ex.: `coloque_seu_path_aqui`. |
| `-TelemetryPath` | Não | Diretório (ou UNC) de destino do CSV. Padrão: `C:\Temp\WAP\JsonBackup`. |

## Uso

```powershell
.\WSLInstall.ps1
.\WSLInstall.ps1 -MsiPath 'coloque_seu_path_aqui' -TelemetryPath 'coloque_seu_path_aqui'
```

Em distribuição via SCCM, execute em Windows PowerShell 64-bit no contexto SYSTEM. Se o processo iniciar em 32-bit, o script relança em `SysNative` preservando `-MsiPath`.

## Fluxo

1. Valida permissão e verifica o runtime com `wsl --version`.
2. Se o runtime não estiver válido, resolve e valida o MSI do pacote.
3. Consulta os recursos `Microsoft-Windows-Subsystem-Linux` e `VirtualMachinePlatform` e habilita os ausentes via DISM (`/norestart`).
4. Instala o MSI quando necessário (`/qn /norestart`, com log detalhado).
5. Retorna `3010` após habilitar recursos ou instalar o runtime.
6. Se nada precisou ser feito e não há recurso pendente, valida `wsl --status` e retorna `0`.

MSI com retorno `0`, `3010` ou `1641` é tratado como instalação bem-sucedida (retorno `3010` ao SCCM). O script não executa restart/shutdown.

| Retorno | Significado |
|---:|---|
| 0 | Recursos habilitados e runtime disponível, sem instalação nesta execução. |
| 3010 | Instalação aceita; reinicialização requerida antes de usar o WSL. |
| 1 | Falha de validação, DISM, MSI ou runtime. |

`3010` não comprova funcionamento antes do reboot; valide depois da reinicialização.

## Logs, cache e detecção

- Log: `C:\Temp\WAP\Logs\PacoteWSL.log`
- Log do MSI: `C:\Temp\WAP\Logs\WSL-runtime-msi.log`
- CSV: `WSLInstall_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.csv`
- Cache: `C:\WAP\WSL`. A flag `.wslinstall-completed` só é gravada em execução sem reboot pendente e **não** deve ser o único critério de detecção. Considere também o produto/runtime MSI instalado e os recursos do Windows habilitados.

## Homologação após o reboot

```bat
wsl --version
wsl --status
dism /online /get-featureinfo /featurename:Microsoft-Windows-Subsystem-Linux
dism /online /get-featureinfo /featurename:VirtualMachinePlatform
```

Os comandos DISM exigem terminal administrativo. Teste também MSI ausente, falha de MSI, recursos em `EnablePending` e reexecução após o reboot.

Guia institucional: [`wap/Instalador-WSL.md`](../../../wap/Instalador-WSL.md)
