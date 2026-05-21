@echo off
chcp 65001 >nul
set "PROJECT_DIR=D:\work\cc"
cd /d %PROJECT_DIR%
title QA
mode con cols=100 lines=30

if exist AgentTeams\inbox\qa\*.processing echo.>AgentTeams\watcher\trigger-qa.txt

echo.
echo ╔══════════════════════════════╗
echo ║  ✅ QA（测试验证）          ║
echo ║  /loop 1m /agent-trigger qa      ║
echo ╚══════════════════════════════╝
echo.
claude --name "QA-测试" "/loop 1m /agent-trigger qa"
