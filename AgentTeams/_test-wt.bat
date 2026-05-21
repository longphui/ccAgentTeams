@echo off
chcp 65001 >nul
"%~dp0tools\terminal-1.25.1171.0\wt.exe" -w 0 --title Architect cmd /k "echo LEFT" ; sp -V --title Developer cmd /k "echo RIGHT"
echo done
pause
