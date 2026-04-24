@echo off

REM Check .env exists
if not exist .env (
    echo Error: Configuration not found
    echo Please run 'setup.bat' first
    exit /b 1
)

REM Load environment variables
for /f "usebackq tokens=1,* delims==" %%a in (.env) do (
    set %%a=%%b
)

REM Check workspace directory exists
if not exist workspace (
    echo Creating workspace directory...
    mkdir workspace
)

REM Start container
echo Starting %RUNTIME_AGENT% agent...
docker compose up -d

REM Wait for container
echo Waiting for container to initialize...
timeout /t 2 /nobreak >nul

REM Check if container is running
docker compose ps | findstr /c:"running" >nul
if errorlevel 1 (
    echo [FAIL] Agent failed to start
    echo Last 20 lines of logs:
    docker compose logs --tail=20
    exit /b 1
)

echo [OK] Agent started successfully

REM Show logs
echo.
echo ========================================
echo Agent is running!
echo ========================================
echo.
echo Attaching to logs (Ctrl+C to detach, won't stop container)...
echo.
docker compose logs -f
