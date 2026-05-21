@echo off
chcp 65001 >nul
cd /d "%~dp0.."
if exist AgentTeams\inboxeviewer\*.processing echo.>AgentTeams\watcher\trigger-reviewer.txt
claude --name Reviewer-审查 "/loop 1m /agent-trigger reviewer"
