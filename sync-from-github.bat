@echo off
cd /d "%~dp0"
title Bobux - GitHub a Roblox Studio
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-from-github.ps1"
pause
