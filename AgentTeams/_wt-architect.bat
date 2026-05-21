@echo off
chcp 65001 >nul
cd /d D:\work\cc
if exist AgentTeams\inboxrchitect\*.processing echo.>AgentTeams\watcher\trigger-architect.txt
claude --name Architect-架构师 /agent-architect
