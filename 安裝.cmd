@echo off
setlocal
chcp 65001 >nul
title AI Memory System - Install (Windows)
echo.
echo ============================================================
echo   AI Memory System  -  one-click install (Windows)
echo   Building the personal memory brain for Claude Code + Codex
echo ============================================================
echo.

rem %~dp0 = the folder this .cmd sits in (with trailing backslash).
rem install-personal.ps1 lives right next to this file, so no path hunting is needed.
if not exist "%~dp0install-personal.ps1" (
  echo [ERROR] install-personal.ps1 not found next to this file.
  echo Make sure you EXTRACTED the ZIP first, then double-click 安裝.cmd inside the extracted folder.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-personal.ps1"
set "RC=%ERRORLEVEL%"

echo.
if not "%RC%"=="0" (
  echo [!] Installer returned code %RC%. If it says settings.json was LOCKED,
  echo     close Claude Code / Codex and double-click this file again.
) else (
  echo Done.
)
echo.
echo Next steps:
echo   1) CLOSE and REOPEN Claude Code / Codex (so new commands load).
echo   2) If a "trust this hook" prompt appears, choose Trust / Allow.
echo   3) Check it: Claude Code type  /status   ; Codex say  看記憶狀態
echo.
pause
endlocal
