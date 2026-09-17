@echo off
setlocal

cd /d "%~dp0"
set "SCRIPT=%~dp0ScriptHub.UI.ps1"

if not exist "%SCRIPT%" (
    echo ScriptHub.UI.ps1 was not found in:
    echo %~dp0
    pause
    exit /b 1
)

rem Windows PowerShell 5.1 provides the best compatibility for this WinForms UI.
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%SCRIPT%"

if errorlevel 1 (
    echo.
    echo ScriptHub ended with an error.
    pause
)

endlocal
