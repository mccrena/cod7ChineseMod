@echo off
if "%~1"=="" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" -GameRoot "%~1"
)
set release_exit=%ERRORLEVEL%
pause
exit /b %release_exit%
