@echo off
chcp 65001 >nul
set "PROJECT_DIR=D:\work\cc"
cd /d %PROJECT_DIR%
title Reviewer
mode con cols=100 lines=30

if exist AgentTeams\inbox\reviewer\*.processing echo.>AgentTeams\watcher\trigger-reviewer.txt

echo.
echo ╔══════════════════════════════╗
echo ║  🔍 Reviewer（代码审查）    ║
echo ║  /loop 1m /agent-trigger reviewer ║
echo ╚══════════════════════════════╝
echo.
claude --name "Reviewer-审查" "/loop 1m /agent-trigger reviewer"
