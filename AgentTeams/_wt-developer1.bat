@echo off
chcp 65001 >nul
cd /d "%~dp0.."
if exist AgentTeams\inbox\developer1\*.processing echo.>AgentTeams\watcher\trigger-developer1.txt
claude --name Developer1-前端 "/loop 1m /agent-trigger developer1"
