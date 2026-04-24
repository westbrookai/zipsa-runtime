@echo off

REM Check if container is running
docker compose ps | findstr /c:"running" >nul
if errorlevel 1 (
    echo Agent is not running
    exit /b 0
)

REM Stop and remove containers
echo Stopping agent...
docker compose down

echo [OK] Agent stopped
echo.
echo Your workspace and configuration are preserved
echo Run 'start.bat' to restart the agent
