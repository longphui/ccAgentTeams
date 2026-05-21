@echo off
chcp 65001 >nul
cd /d "%~dp0.."
title Developer
mode con cols=100 lines=30

:: 中断恢复：检测是否有未完成的 .processing 任务，自动补 trigger
if exist AgentTeams\inbox\developer\*.processing echo.>AgentTeams\watcher\trigger-developer.txt

echo.
echo ╔══════════════════════════════╗
echo ║  🔧 Developer（后端）       ║
echo ║  /loop 1m /agent-trigger developer ║
echo ╚══════════════════════════════╝
echo.
claude --name "Developer-后端" "/loop 1m /agent-trigger developer"
