@echo off
chcp 65001 >nul
set "PROJECT_DIR=D:\work\cc"
cd /d %PROJECT_DIR%
title Developer1
mode con cols=100 lines=30

if exist AgentTeams\inbox\developer1\*.processing echo.>AgentTeams\watcher\trigger-developer1.txt

echo.
echo ╔══════════════════════════════╗
echo ║  🎨 Developer1（前端）      ║
echo ║  /loop 1m /agent-trigger developer1 ║
echo ╚══════════════════════════════╝
echo.
claude --name "Developer1-前端" "/loop 1m /agent-trigger developer1"
