@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\start-game.ps1" %*
set "GAME_RUN_EXIT=%errorlevel%"
if not "%GAME_RUN_EXIT%"=="0" pause
exit /b %GAME_RUN_EXIT%
