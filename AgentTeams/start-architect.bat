@echo off
chcp 65001 >nul
set "PROJECT_DIR=D:\work\cc"
cd /d %PROJECT_DIR%
title Architect
mode con cols=100 lines=30

if exist AgentTeams\inbox\architect\*.processing echo.>AgentTeams\watcher\trigger-architect.txt

echo.
echo ╔══════════════════════════════╗
echo ║  🏛️  Architect（架构师）     ║
echo ╚══════════════════════════════╝
echo.
claude --name "Architect-架构师" "/agent-architect"
