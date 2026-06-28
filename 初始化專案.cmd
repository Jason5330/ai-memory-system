@echo off
setlocal
chcp 65001 >nul
title AI Memory System - Init Project (Windows)
echo.
echo ============================================================
echo   AI Memory System  -  initialize a project (optional)
echo ============================================================
echo.
echo Most users do NOT need this. The personal brain already works
echo everywhere. Only init a project if you want THIS project's
echo knowledge to travel with its git repo.
echo.

rem Drag your PROJECT folder onto this .cmd and release, OR run it from
rem inside the project. %~1 = the dropped/passed folder; else current dir.
set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=%CD%"

echo Target project folder:
echo   %TARGET%
echo.

if not exist "%~dp0init-project.ps1" (
  echo [ERROR] init-project.ps1 not found next to this file. Extract the ZIP first.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0init-project.ps1" "%TARGET%"
echo.
echo Done. Reopen Claude Code / Codex in that project.
echo.
pause
endlocal
