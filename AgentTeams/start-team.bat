@echo off
chcp 65001 >nul
echo === Starting Team (5 Agents) ===
powershell -ExecutionPolicy Bypass -File "%~dp0start-team.ps1"
echo Done
pause
