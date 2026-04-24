@echo off
REM ============================================================================
REM Stop Script for Minimal Agent (Windows)
REM ============================================================================
REM
REM This script stops the running minimal-agent Docker container.
REM
REM Usage: stop.bat
REM ============================================================================

echo ============================================================================
echo Stopping Minimal Agent
echo ============================================================================
echo.

REM Check if container exists and is running
docker ps --format "{{.Names}}" | findstr /x "minimal-agent" >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Stopping container...
    docker stop minimal-agent
    echo [OK] Container stopped
) else (
    echo [INFO] Container 'minimal-agent' is not running
)

echo.
pause
