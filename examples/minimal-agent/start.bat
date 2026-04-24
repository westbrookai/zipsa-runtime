@echo off
REM ============================================================================
REM Start Script for Minimal Agent (Windows)
REM ============================================================================
REM
REM This script starts the minimal-agent Docker container with:
REM - Environment variables from .env file
REM - Port mapping from .env
REM - Detached mode (runs in background)
REM - Auto-restart on failure
REM - Container name for easy management
REM
REM Usage: start.bat
REM ============================================================================

setlocal enabledelayedexpansion

echo ============================================================================
echo Starting Minimal Agent
echo ============================================================================
echo.

REM Check if .env file exists
if not exist .env (
    echo [ERROR] .env file not found
    echo Please run setup.bat first
    pause
    exit /b 1
)

REM Load PORT from .env (simple parsing)
for /f "tokens=2 delims==" %%a in ('findstr /b "PORT=" .env') do set PORT=%%a

REM Check if container already exists
docker ps -a --format "{{.Names}}" | findstr /x "minimal-agent" >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Container 'minimal-agent' already exists

    REM Check if it's running
    docker ps --format "{{.Names}}" | findstr /x "minimal-agent" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] Container is already running
        echo.
        echo Agent is available at: http://localhost:!PORT!
        pause
        exit /b 0
    )

    echo [INFO] Starting existing container...
    docker start minimal-agent
) else (
    echo [INFO] Creating and starting new container...
    docker run -d --name minimal-agent --env-file .env -p "!PORT!:3000" --restart unless-stopped minimal-agent
)

echo.
echo ============================================================================
echo Agent Started Successfully
echo ============================================================================
echo.
echo Agent is available at: http://localhost:!PORT!
echo.
echo Useful commands:
echo   View logs:  docker logs minimal-agent
echo   Stop agent: stop.bat
echo.
pause
