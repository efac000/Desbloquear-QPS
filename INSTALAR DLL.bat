@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Desbloquear QPS - Instalar DLL
cd /d "%~dp0"
if not exist "%~dp0tools\instalar_workshop.ps1" (
  echo ERRO: extraia TODO o ZIP antes de executar INSTALAR DLL.bat
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0tools\instalar_workshop.ps1"
set "CODIGO=%ERRORLEVEL%"
echo.
if "%CODIGO%"=="0" (
 echo Operacao concluida com sucesso. Confira o resultado acima.
) else (
 echo Instalacao interrompida. Leia a mensagem de erro acima.
)
echo.
pause
exit /b %CODIGO%
