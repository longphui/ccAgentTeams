@echo off
chcp 65001 >nul
cd /d D:\work\cc
if exist AgentTeams\inbox\developer1\*.processing echo.>AgentTeams\watcher\trigger-developer1.txt
claude --name Developer1-前端 "/loop 1m /agent-trigger developer1"
