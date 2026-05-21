@echo off
chcp 65001 >nul
cd /d "%~dp0.."
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
