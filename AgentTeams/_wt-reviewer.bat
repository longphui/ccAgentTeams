@echo off
chcp 65001 >nul
cd /d D:\work\cc
if exist AgentTeams\inboxeviewer\*.processing echo.>AgentTeams\watcher\trigger-reviewer.txt
claude --name Reviewer-审查 "/loop 1m /agent-trigger reviewer"
