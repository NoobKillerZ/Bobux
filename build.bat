@echo off
cd /d "%~dp0"
".tools\lune.exe" run build.lua
echo.
pause
