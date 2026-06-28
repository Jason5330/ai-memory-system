@echo off
setlocal
chcp 65001 >nul
title AI Memory System - Init Project (Windows)
echo.
echo ============================================================
echo   AI Memory System  -  initialize a project (optional)
echo ============================================================
echo.
echo Most users do NOT need this. The global brain already works
echo everywhere. Init a project only if you want THIS project's
echo knowledge to travel with its git repo.
echo.

rem --- Pick the TARGET project folder ---
rem   - Drag a folder onto this .cmd  -> %~1 is that folder.
rem   - Copy this .cmd INTO a project and double-click -> use this file's own folder (%~dp0).
set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=%~dp0"
rem strip trailing backslash for cleanliness
if "%TARGET:~-1%"=="\" set "TARGET=%TARGET:~0,-1%"

rem --- Locate init-project.ps1 ---
rem   1) next to this .cmd (running from the framework folder), else
rem   2) the global brain (installed by 安裝.cmd): %AI_MEMORY_HOME% or %USERPROFILE%\.ai-memory
set "IP=%~dp0init-project.ps1"
if not exist "%IP%" if defined AI_MEMORY_HOME set "IP=%AI_MEMORY_HOME%\init-project.ps1"
if not exist "%IP%" set "IP=%USERPROFILE%\.ai-memory\init-project.ps1"

if not exist "%IP%" (
  echo [ERROR] Cannot find init-project.ps1.
  echo Run 安裝.cmd once first ^(it installs the global brain^), then try again.
  echo.
  pause
  exit /b 1
)

echo Target project folder:
echo   %TARGET%
echo Using:
echo   %IP%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%IP%" "%TARGET%"
echo.
echo Done. Reopen Claude Code / Codex in that project folder.
echo.
pause
endlocal
