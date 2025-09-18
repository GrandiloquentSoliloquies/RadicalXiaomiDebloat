@echo off
TITLE ADB Utility Script Launcher

:: This batch file launches the main PowerShell script.
:: It automatically finds the script's location and uses the -ExecutionPolicy Bypass flag
:: for maximum portability and ease of use.

echo =======================================================
echo           PowerShell ADB Utility Launcher
echo =======================================================
echo.
echo Initializing PowerShell script... Please wait.
echo.

:: Get the directory where this batch file is located.
set "SCRIPT_DIR=%~dp0"

:: Set the full path to the PowerShell script we want to run.
set "PS_SCRIPT_PATH=%SCRIPT_DIR%adb_debloat_from_list.ps1"

:: Execute the PowerShell script.
:: -NoProfile: Starts PowerShell faster.
:: -ExecutionPolicy Bypass: Ignores the execution policy for this session only.
:: -File: Specifies the script to run.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT_PATH%"

echo.
echo =======================================================
echo Script has finished its tasks.
echo This window will close after you press a key.
echo =======================================================
echo.
pause
