@echo off
setlocal

cd /d "%~dp0"
set "SCRIPT=%~dp0ScriptHub.UI.ps1"

if not exist "%SCRIPT%" (
    echo No se encontro ScriptHub.UI.ps1 en:
    echo %~dp0
    pause
    exit /b 1
)

rem WinForms usa Windows PowerShell 5.1 para mayor compatibilidad.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

if errorlevel 1 (
    echo.
    echo ScriptHub termino con un error.
    pause
)

endlocal
