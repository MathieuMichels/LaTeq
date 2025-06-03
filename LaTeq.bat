@echo off
REM LaTeq Windows Batch Wrapper
REM This batch file calls the PowerShell script LaTeq.ps1
REM Usage: LaTeq.bat "equation" [options]

REM Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: PowerShell is not available or not in PATH
    echo Please make sure PowerShell is installed and accessible
    exit /b 1
)

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Check if LaTeq.ps1 exists
if not exist "%SCRIPT_DIR%LaTeq.ps1" (
    echo Error: LaTeq.ps1 not found in %SCRIPT_DIR%
    echo Please make sure LaTeq.ps1 is in the same directory as this batch file
    exit /b 1
)

REM Execute the PowerShell script with all arguments
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%LaTeq.ps1" %*
