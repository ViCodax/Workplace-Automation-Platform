# Instalador WSL

## Responsabilidade

Aplicativo SCCM de dispositivo, executado como SYSTEM. Habilita os recursos opcionais Microsoft-Windows-Subsystem-Linux e VirtualMachinePlatform e instala o runtime moderno WSL via MSI quando necessario. Nao importa distribuicao Linux, nao instala Docker e nao agenda execucao por usuario.

## Resultado e reinicializacao

- Retorna `3010` quando habilita recursos ou instala runtime, para o SCCM gerenciar a reinicializacao.
- Retorna `0` quando runtime e recursos ja estao prontos e validados.
- Retorna `1` em falha de validacao, DISM, MSI ou runtime.

Para um pacote ja instalado, a validacao exige os dois recursos habilitados e sucesso em `wsl --version`. A consulta `wsl --status` tem seu codigo e saida registrados no log, mas um retorno diferente de zero gera apenas aviso: essa consulta pode depender do contexto do usuario e de suas distribuicoes, que nao sao responsabilidade deste pacote SYSTEM.

A disponibilidade funcional deve ser validada depois do reboot. Uma flag de sucesso nao substitui deteccao do runtime e dos recursos do Windows.

## Arquivos e operacao

Implementacao: `scripts/Instaladores/WSL/WSLInstall.ps1`, com MSI WSL incluido no pacote. O instalador nao baixa MSI nem faz fallback silencioso para runtime inbox. O comando SCCM e requisitos completos estao no [guia tecnico WSL](../scripts/Instaladores/WSL/README.md).

Logs: `C:\Temp\WAP\Logs\PacoteWSL.log` e `WSL-runtime-msi.log`. Telemetria WAP em CSV na rede com backup local. Estimativa de economia: 30 minutos por instalacao bem-sucedida.
