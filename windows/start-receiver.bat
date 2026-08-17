@echo off
set SCRIPT_DIR=%~dp0
powershell -ExecutionPolicy Bypass -File "Receive-Sail3dl.ps1"
