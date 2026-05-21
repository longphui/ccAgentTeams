@echo off
chcp 65001 >nul
cd /d "%~dp0.."
if exist AgentTeams\inbox\developer\*.processing echo.>AgentTeams\watcher\trigger-developer.txt
claude --name Developer-后端 "/loop 1m /agent-trigger developer"
