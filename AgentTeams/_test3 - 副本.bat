@echo off
chcp 65001 >nul
echo === 3格测试(去掉move-focus right) ===
"C:\Program Files\terminal-1.25.1171.0\wt.exe" -w 0 -d D:\work\cc\AgentTeams --title "Architect" cmd /k "echo Architect" ; sp -V -s 0.5 -d D:\work\cc\AgentTeams --title "Developer" cmd /k "echo Developer" ; sp -H -s 0.5 -d D:\work\cc\AgentTeams --title "Reviewer" cmd /k "echo Reviewer"
echo done
pause
