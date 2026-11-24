@echo off
chcp 65001 >nul
title Money - local server
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
pause
