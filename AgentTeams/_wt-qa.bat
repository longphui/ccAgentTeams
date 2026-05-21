@echo off
chcp 65001 >nul
cd /d D:\work\cc
if exist AgentTeams\inbox\qa\*.processing echo.>AgentTeams\watcher\trigger-qa.txt
claude --name QA-测试 "/loop 1m /agent-trigger qa"
