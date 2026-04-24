# Docker Compose Agent Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a reference implementation of Docker Compose-based domain agent deployment in `examples/minimal-agent/` with complete scripts, tests, and documentation.

**Architecture:** Example agent demonstrates interactive setup scripts that generate `.env` files, simple start/stop wrappers around `docker compose`, and integration tests. All components follow the design spec for customer-facing deployment.

**Tech Stack:** Bash scripts, Docker Compose 3.8, integration testing with shell scripts

---

## File Structure

### New Files to Create

```
examples/minimal-agent/
├── docker-compose.yml           # Container orchestration config
├── .env.example                 # Environment variable template
├── .gitignore                   # Git ignore patterns
├── setup.sh                     # Interactive setup (Linux/macOS)
├── setup.bat                    # Interactive setup (Windows)
├── start.sh                     # Start agent (Linux/macOS)
├── start.bat                    # Start agent (Windows)
├── stop.sh                      # Stop agent (Linux/macOS)
├── stop.bat                     # Stop agent (Windows)
├── README.md                    # Customer documentation
├── test-setup.sh                # Integration tests
├── skills/                      # Example skill directory
│   └── hello-world/
│       ├── skill.md             # Example SKILL
│       └── metadata.json        # SKILL metadata
├── servers.json                 # MCP server configuration
└── workspace/                   # User workspace (created at runtime)

.github/workflows/
└── test-compose.yml             # CI workflow for testing

README.md                        # Update with Docker Compose section
```

### Files to Modify

- `README.md:20-25` - Add Docker Compose usage section after Quick Start

---

## Task 1: Create Directory Structure and .gitignore

**Files:**
- Create: `examples/minimal-agent/.gitignore`
- Create: `examples/minimal-agent/workspace/.gitkeep`
- Create: `examples/minimal-agent/skills/hello-world/.gitkeep`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p examples/minimal-agent/skills/hello-world
mkdir -p examples/minimal-agent/workspace
```

- [ ] **Step 2: Create .gitignore**

Create `examples/minimal-agent/.gitignore`:

```gitignore
# Environment configuration
.env

# Logs
*.log
logs/

# Docker volumes
docker-compose.override.yml

# OS files
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo
```

- [ ] **Step 3: Create placeholder files**

Create `examples/minimal-agent/workspace/.gitkeep` (empty file):
```bash
touch examples/minimal-agent/workspace/.gitkeep
```

Create `examples/minimal-agent/skills/hello-world/.gitkeep` (empty file):
```bash
touch examples/minimal-agent/skills/hello-world/.gitkeep
```

- [ ] **Step 4: Verify structure**

Run: `tree examples/minimal-agent -a`

Expected: Directory structure matches plan

- [ ] **Step 5: Commit**

```bash
git add examples/minimal-agent
git commit -m "feat: create minimal-agent directory structure"
```

---

## Task 2: Create docker-compose.yml

**Files:**
- Create: `examples/minimal-agent/docker-compose.yml`
- Test: Will be validated in Task 12 integration tests

- [ ] **Step 1: Create docker-compose.yml**

Create `examples/minimal-agent/docker-compose.yml`:

```yaml
version: '3.8'

services:
  minimal-agent:
    image: ghcr.io/westbrookai/zipsa-runtime:latest
    container_name: minimal-agent
    stdin_open: true
    tty: true

    environment:
      # API Keys from .env
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - GOOGLE_OAUTH_CLIENT_ID=${GOOGLE_OAUTH_CLIENT_ID:-}
      - GOOGLE_OAUTH_CLIENT_SECRET=${GOOGLE_OAUTH_CLIENT_SECRET:-}

      # Runtime selection
      - RUNTIME_AGENT=${RUNTIME_AGENT:-claude}

      # Terminal settings
      - TERM=xterm-256color

    volumes:
      # Mount skills directory (read-only for safety)
      - ./skills:/root/.claude/skills:ro

      # Mount MCP server config
      - ./servers.json:/app/servers.json:ro

      # Mount workspace for user projects
      - ./workspace:/workspace

      # Optional: persist Claude settings across restarts
      - claude-config:/root/.claude/config

    working_dir: /workspace

    # Command varies by runtime
    command: >
      sh -c "
        case $${RUNTIME_AGENT} in
          claude) claude --mcp-config /app/servers.json ;;
          codex) codex --mcp-config /app/servers.json ;;
          gemini) gemini --mcp-config /app/servers.json ;;
          *) echo 'Invalid RUNTIME_AGENT' && exit 1 ;;
        esac
      "

    # Restart policy
    restart: unless-stopped

volumes:
  claude-config:
    name: minimal-agent-config
```

- [ ] **Step 2: Validate YAML syntax**

Run: `docker compose -f examples/minimal-agent/docker-compose.yml config > /dev/null`

Expected: No syntax errors

- [ ] **Step 3: Commit**

```bash
git add examples/minimal-agent/docker-compose.yml
git commit -m "feat: add docker-compose.yml for minimal-agent"
```

---

## Task 3: Create .env.example

**Files:**
- Create: `examples/minimal-agent/.env.example`

- [ ] **Step 1: Create .env.example**

Create `examples/minimal-agent/.env.example`:

```bash
# API Keys - Replace with your actual keys
ANTHROPIC_API_KEY=your-anthropic-api-key-here

# Optional: Google OAuth credentials
# GOOGLE_OAUTH_CLIENT_ID=your-google-client-id
# GOOGLE_OAUTH_CLIENT_SECRET=your-google-client-secret

# Runtime Selection: claude, codex, or gemini
RUNTIME_AGENT=claude
```

- [ ] **Step 2: Verify format**

Run: `cat examples/minimal-agent/.env.example`

Expected: File contains template variables

- [ ] **Step 3: Commit**

```bash
git add examples/minimal-agent/.env.example
git commit -m "feat: add environment variable template"
```

---

## Task 4: Create Example SKILL

**Files:**
- Create: `examples/minimal-agent/skills/hello-world/skill.md`
- Create: `examples/minimal-agent/skills/hello-world/metadata.json`
- Delete: `examples/minimal-agent/skills/hello-world/.gitkeep`

- [ ] **Step 1: Create skill.md**

Create `examples/minimal-agent/skills/hello-world/skill.md`:

```markdown
---
name: hello-world
description: Simple greeting skill to verify agent is working
---

# Hello World Skill

This is a minimal example skill to verify the agent runtime is working correctly.

When the user says "hello" or "hi", respond with:

> Hello! I'm your Minimal Agent running on [runtime-name]. I'm here to help you test the zipsa-runtime setup. Everything is working correctly!

Where [runtime-name] is replaced with the actual runtime (Claude, Codex, or Gemini).

## Usage

This skill is automatically loaded when the agent starts. Try saying:
- "hello"
- "hi"
- "test the setup"

The agent should respond with a friendly greeting confirming it's running.
```

- [ ] **Step 2: Create metadata.json**

Create `examples/minimal-agent/skills/hello-world/metadata.json`:

```json
{
  "name": "hello-world",
  "version": "1.0.0",
  "description": "Simple greeting skill for testing agent setup",
  "author": "WestbrookAI",
  "tags": ["example", "testing", "setup"],
  "dependencies": []
}
```

- [ ] **Step 3: Remove placeholder file**

```bash
rm examples/minimal-agent/skills/hello-world/.gitkeep
```

- [ ] **Step 4: Verify skill structure**

Run: `ls -la examples/minimal-agent/skills/hello-world/`

Expected: skill.md and metadata.json exist

- [ ] **Step 5: Commit**

```bash
git add examples/minimal-agent/skills/hello-world
git commit -m "feat: add hello-world example skill"
```

---

## Task 5: Create servers.json

**Files:**
- Create: `examples/minimal-agent/servers.json`

- [ ] **Step 1: Create servers.json**

Create `examples/minimal-agent/servers.json`:

```json
{
  "mcpServers": {
    "time": {
      "command": "uvx",
      "args": ["mcp-server-time", "--local-timezone=UTC"]
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

- [ ] **Step 2: Validate JSON syntax**

Run: `cat examples/minimal-agent/servers.json | python3 -m json.tool > /dev/null`

Expected: No JSON syntax errors

- [ ] **Step 3: Commit**

```bash
git add examples/minimal-agent/servers.json
git commit -m "feat: add MCP server configuration"
```

---

## Task 6: Create setup.sh (Linux/macOS)

**Files:**
- Create: `examples/minimal-agent/setup.sh`

- [ ] **Step 1: Create setup.sh**

Create `examples/minimal-agent/setup.sh`:

```bash
#!/bin/bash
set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Welcome message
echo ""
echo "════════════════════════════════════════"
echo "  Minimal Agent Setup"
echo "════════════════════════════════════════"
echo ""

# Check Docker availability
echo "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker Desktop from https://docker.com"
    exit 1
fi

# Verify Docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

echo -e "${GREEN}✓ Docker is available${NC}"

# Check for existing .env
if [ -f .env ]; then
    echo ""
    echo -e "${YELLOW}.env already exists${NC}"
    read -p "Reconfigure? (y/n): " reconfigure
    if [ "$reconfigure" != "y" ]; then
        echo "Keeping existing configuration"
        exit 0
    fi
    echo "Reconfiguring..."
fi

# Prompt for API key
echo ""
read -sp "Enter your ANTHROPIC_API_KEY: " api_key
echo ""

# Basic validation (starts with sk-)
if [[ ! $api_key =~ ^sk- ]]; then
    echo -e "${YELLOW}⚠ Warning: API key should start with 'sk-'${NC}"
    read -p "Continue anyway? (y/n): " continue
    if [ "$continue" != "y" ]; then
        echo "Setup cancelled"
        exit 1
    fi
fi

# Optional: Google OAuth
echo ""
read -p "Do you need Google OAuth credentials? (y/n): " needs_google
google_id=""
google_secret=""

if [ "$needs_google" = "y" ]; then
    read -p "GOOGLE_OAUTH_CLIENT_ID: " google_id
    read -sp "GOOGLE_OAUTH_CLIENT_SECRET: " google_secret
    echo ""
fi

# Runtime selection
echo ""
echo "Select runtime agent:"
echo "1) Claude (Recommended)"
echo "2) Codex"
echo "3) Gemini"
read -p "Choice (1-3): " runtime_choice

case $runtime_choice in
    1) runtime="claude" ;;
    2) runtime="codex" ;;
    3) runtime="gemini" ;;
    *)
        echo -e "${YELLOW}Invalid choice. Defaulting to Claude.${NC}"
        runtime="claude"
        ;;
esac

# Generate .env file
cat > .env << EOF
# Generated by setup.sh on $(date)
ANTHROPIC_API_KEY=${api_key}
RUNTIME_AGENT=${runtime}
EOF

if [ "$needs_google" = "y" ]; then
    cat >> .env << EOF
GOOGLE_OAUTH_CLIENT_ID=${google_id}
GOOGLE_OAUTH_CLIENT_SECRET=${google_secret}
EOF
fi

echo -e "${GREEN}✓ Configuration saved to .env${NC}"

# Pull latest runtime image
echo ""
echo "Pulling latest zipsa-runtime image..."
if docker pull ghcr.io/westbrookai/zipsa-runtime:latest; then
    echo -e "${GREEN}✓ Runtime image downloaded${NC}"
else
    echo -e "${YELLOW}⚠ Failed to pull image. Will retry on first start.${NC}"
fi

# Success message
echo ""
echo "════════════════════════════════════════"
echo -e "${GREEN}✓ Setup complete!${NC}"
echo "════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Run './start.sh' to launch the agent"
echo "  2. Wait for initialization to complete"
echo "  3. Start chatting with your agent"
echo ""
```

- [ ] **Step 2: Make executable**

```bash
chmod +x examples/minimal-agent/setup.sh
```

- [ ] **Step 3: Verify script syntax**

Run: `bash -n examples/minimal-agent/setup.sh`

Expected: No syntax errors

- [ ] **Step 4: Commit**

```bash
git add examples/minimal-agent/setup.sh
git commit -m "feat: add interactive setup script for Linux/macOS"
```

---

## Task 7: Create setup.bat (Windows)

**Files:**
- Create: `examples/minimal-agent/setup.bat`

- [ ] **Step 1: Create setup.bat**

Create `examples/minimal-agent/setup.bat`:

```batch
@echo off
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   Minimal Agent Setup
echo ========================================
echo.

REM Check Docker availability
echo Checking Docker installation...
docker --version >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not installed
    echo Please install Docker Desktop from https://docker.com
    exit /b 1
)

REM Verify Docker daemon is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not running
    echo Please start Docker Desktop and try again
    exit /b 1
)

echo [OK] Docker is available
echo.

REM Check for existing .env
if exist .env (
    echo .env already exists
    set /p reconfigure="Reconfigure? (y/n): "
    if /i not "!reconfigure!"=="y" (
        echo Keeping existing configuration
        exit /b 0
    )
    echo Reconfiguring...
)

REM Prompt for API key
echo.
set /p api_key="Enter your ANTHROPIC_API_KEY: "

REM Basic validation
echo !api_key! | findstr /r /c:"^sk-" >nul
if errorlevel 1 (
    echo Warning: API key should start with 'sk-'
    set /p continue="Continue anyway? (y/n): "
    if /i not "!continue!"=="y" (
        echo Setup cancelled
        exit /b 1
    )
)

REM Optional: Google OAuth
echo.
set /p needs_google="Do you need Google OAuth credentials? (y/n): "
set google_id=
set google_secret=

if /i "!needs_google!"=="y" (
    set /p google_id="GOOGLE_OAUTH_CLIENT_ID: "
    set /p google_secret="GOOGLE_OAUTH_CLIENT_SECRET: "
)

REM Runtime selection
echo.
echo Select runtime agent:
echo 1^) Claude (Recommended)
echo 2^) Codex
echo 3^) Gemini
set /p runtime_choice="Choice (1-3): "

if "!runtime_choice!"=="1" set runtime=claude
if "!runtime_choice!"=="2" set runtime=codex
if "!runtime_choice!"=="3" set runtime=gemini
if "!runtime!"=="" (
    echo Invalid choice. Defaulting to Claude.
    set runtime=claude
)

REM Generate .env file
(
echo # Generated by setup.bat on %date% %time%
echo ANTHROPIC_API_KEY=!api_key!
echo RUNTIME_AGENT=!runtime!
) > .env

if /i "!needs_google!"=="y" (
    (
    echo GOOGLE_OAUTH_CLIENT_ID=!google_id!
    echo GOOGLE_OAUTH_CLIENT_SECRET=!google_secret!
    ) >> .env
)

echo [OK] Configuration saved to .env

REM Pull latest runtime image
echo.
echo Pulling latest zipsa-runtime image...
docker pull ghcr.io/westbrookai/zipsa-runtime:latest
if errorlevel 1 (
    echo Warning: Failed to pull image. Will retry on first start.
) else (
    echo [OK] Runtime image downloaded
)

REM Success message
echo.
echo ========================================
echo [OK] Setup complete!
echo ========================================
echo.
echo Next steps:
echo   1. Run 'start.bat' to launch the agent
echo   2. Wait for initialization to complete
echo   3. Start chatting with your agent
echo.

endlocal
```

- [ ] **Step 2: Verify batch syntax**

Run: `cmd /c "examples/minimal-agent/setup.bat /?" 2>&1 | head -n 5`

Expected: No syntax errors (script should run help or start)

- [ ] **Step 3: Commit**

```bash
git add examples/minimal-agent/setup.bat
git commit -m "feat: add interactive setup script for Windows"
```

---

## Task 8: Create start.sh (Linux/macOS)

**Files:**
- Create: `examples/minimal-agent/start.sh`

- [ ] **Step 1: Create start.sh**

Create `examples/minimal-agent/start.sh`:

```bash
#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check .env exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: Configuration not found${NC}"
    echo "Please run './setup.sh' first"
    exit 1
fi

# Load environment variables
source .env

# Check workspace directory exists
if [ ! -d workspace ]; then
    echo "Creating workspace directory..."
    mkdir -p workspace
fi

# Start container
echo "Starting ${RUNTIME_AGENT} agent..."
docker compose up -d

# Wait for container to be healthy
echo "Waiting for container to initialize..."
sleep 2

# Check if container is running
if docker compose ps | grep -q "running"; then
    echo -e "${GREEN}✓ Agent started successfully${NC}"
else
    echo -e "${RED}✗ Agent failed to start${NC}"
    echo "Last 20 lines of logs:"
    docker compose logs --tail=20
    exit 1
fi

# Show logs
echo ""
echo "════════════════════════════════════════"
echo "Agent is running!"
echo "════════════════════════════════════════"
echo ""
echo "Attaching to logs (Ctrl+C to detach, won't stop container)..."
echo ""
docker compose logs -f
```

- [ ] **Step 2: Make executable**

```bash
chmod +x examples/minimal-agent/start.sh
```

- [ ] **Step 3: Verify script syntax**

Run: `bash -n examples/minimal-agent/start.sh`

Expected: No syntax errors

- [ ] **Step 4: Commit**

```bash
git add examples/minimal-agent/start.sh
git commit -m "feat: add start script for Linux/macOS"
```

---

## Task 9: Create start.bat (Windows)

**Files:**
- Create: `examples/minimal-agent/start.bat`

- [ ] **Step 1: Create start.bat**

Create `examples/minimal-agent/start.bat`:

```batch
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
```

- [ ] **Step 2: Verify batch syntax**

Run: `cmd /c "examples/minimal-agent/start.bat /?" 2>&1 | head -n 5`

Expected: No syntax errors

- [ ] **Step 3: Commit**

```bash
git add examples/minimal-agent/start.bat
git commit -m "feat: add start script for Windows"
```

---

## Task 10: Create stop.sh (Linux/macOS)

**Files:**
- Create: `examples/minimal-agent/stop.sh`

- [ ] **Step 1: Create stop.sh**

Create `examples/minimal-agent/stop.sh`:

```bash
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if container is running
if ! docker compose ps | grep -q "running"; then
    echo "Agent is not running"
    exit 0
fi

# Stop and remove containers
echo "Stopping agent..."
docker compose down

# Note: Volumes are preserved by default
echo -e "${GREEN}✓ Agent stopped${NC}"
echo ""
echo "Your workspace and configuration are preserved"
echo "Run './start.sh' to restart the agent"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x examples/minimal-agent/stop.sh
```

- [ ] **Step 3: Verify script syntax**

Run: `bash -n examples/minimal-agent/stop.sh`

Expected: No syntax errors

- [ ] **Step 4: Commit**

```bash
git add examples/minimal-agent/stop.sh
git commit -m "feat: add stop script for Linux/macOS"
```

---

## Task 11: Create stop.bat (Windows)

**Files:**
- Create: `examples/minimal-agent/stop.bat`

- [ ] **Step 1: Create stop.bat**

Create `examples/minimal-agent/stop.bat`:

```batch
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
```

- [ ] **Step 2: Verify batch syntax**

Run: `cmd /c "examples/minimal-agent/stop.bat /?" 2>&1 | head -n 5`

Expected: No syntax errors

- [ ] **Step 3: Commit**

```bash
git add examples/minimal-agent/stop.bat
git commit -m "feat: add stop script for Windows"
```

---

## Task 12: Create Integration Tests

**Files:**
- Create: `examples/minimal-agent/test-setup.sh`

- [ ] **Step 1: Create test-setup.sh**

Create `examples/minimal-agent/test-setup.sh`:

```bash
#!/bin/bash
# Integration tests for minimal-agent setup

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Running integration tests for minimal-agent..."
echo ""

# Test 1: docker-compose.yml is valid
test_compose_valid() {
    echo "Test 1: docker-compose.yml validation"

    if docker compose config > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} docker-compose.yml is valid"
    else
        echo -e "  ${RED}✗${NC} docker-compose.yml has syntax errors"
        docker compose config
        exit 1
    fi
}

# Test 2: .env.example exists and has required variables
test_env_example() {
    echo "Test 2: .env.example validation"

    if [ -f .env.example ]; then
        echo -e "  ${GREEN}✓${NC} .env.example exists"
    else
        echo -e "  ${RED}✗${NC} .env.example missing"
        exit 1
    fi

    # Check for required variables
    grep -q "ANTHROPIC_API_KEY" .env.example || (echo -e "  ${RED}✗${NC} Missing ANTHROPIC_API_KEY"; exit 1)
    grep -q "RUNTIME_AGENT" .env.example || (echo -e "  ${RED}✗${NC} Missing RUNTIME_AGENT"; exit 1)
    echo -e "  ${GREEN}✓${NC} .env.example has required variables"
}

# Test 3: Skills directory exists
test_skills_exist() {
    echo "Test 3: Skills directory structure"

    if [ -d skills/hello-world ]; then
        echo -e "  ${GREEN}✓${NC} skills/hello-world/ exists"
    else
        echo -e "  ${RED}✗${NC} skills/hello-world/ missing"
        exit 1
    fi

    if [ -f skills/hello-world/skill.md ]; then
        echo -e "  ${GREEN}✓${NC} skill.md exists"
    else
        echo -e "  ${RED}✗${NC} skill.md missing"
        exit 1
    fi

    if [ -f skills/hello-world/metadata.json ]; then
        echo -e "  ${GREEN}✓${NC} metadata.json exists"
    else
        echo -e "  ${RED}✗${NC} metadata.json missing"
        exit 1
    fi
}

# Test 4: MCP config exists and is valid JSON
test_mcp_config() {
    echo "Test 4: MCP configuration"

    if [ -f servers.json ]; then
        echo -e "  ${GREEN}✓${NC} servers.json exists"
    else
        echo -e "  ${RED}✗${NC} servers.json missing"
        exit 1
    fi

    # Validate JSON
    if python3 -m json.tool servers.json > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} servers.json is valid JSON"
    else
        echo -e "  ${RED}✗${NC} servers.json is invalid JSON"
        exit 1
    fi

    # Check for MCP servers
    grep -q "mcpServers" servers.json || (echo -e "  ${RED}✗${NC} Missing mcpServers"; exit 1)
    echo -e "  ${GREEN}✓${NC} servers.json has mcpServers"
}

# Test 5: .gitignore includes .env
test_gitignore() {
    echo "Test 5: .gitignore configuration"

    if [ -f .gitignore ]; then
        echo -e "  ${GREEN}✓${NC} .gitignore exists"
    else
        echo -e "  ${RED}✗${NC} .gitignore missing"
        exit 1
    fi

    if grep -q "^\.env$" .gitignore; then
        echo -e "  ${GREEN}✓${NC} .env is gitignored"
    else
        echo -e "  ${RED}✗${NC} .env not in .gitignore"
        exit 1
    fi
}

# Test 6: All scripts exist and are executable (Linux/macOS)
test_scripts_exist() {
    echo "Test 6: Script files"

    for script in setup.sh start.sh stop.sh; do
        if [ -f $script ]; then
            echo -e "  ${GREEN}✓${NC} $script exists"
        else
            echo -e "  ${RED}✗${NC} $script missing"
            exit 1
        fi

        if [ -x $script ]; then
            echo -e "  ${GREEN}✓${NC} $script is executable"
        else
            echo -e "  ${RED}✗${NC} $script not executable"
            exit 1
        fi
    done

    # Check batch files exist (don't check executable on Linux)
    for script in setup.bat start.bat stop.bat; do
        if [ -f $script ]; then
            echo -e "  ${GREEN}✓${NC} $script exists"
        else
            echo -e "  ${RED}✗${NC} $script missing"
            exit 1
        fi
    done
}

# Test 7: README exists
test_readme() {
    echo "Test 7: Documentation"

    if [ -f README.md ]; then
        echo -e "  ${GREEN}✓${NC} README.md exists"
    else
        echo -e "  ${RED}✗${NC} README.md missing"
        exit 1
    fi
}

# Run all tests
test_compose_valid
test_env_example
test_skills_exist
test_mcp_config
test_gitignore
test_scripts_exist
test_readme

echo ""
echo "════════════════════════════════════════"
echo -e "${GREEN}All tests passed!${NC}"
echo "════════════════════════════════════════"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x examples/minimal-agent/test-setup.sh
```

- [ ] **Step 3: Run tests**

Run: `cd examples/minimal-agent && ./test-setup.sh`

Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add examples/minimal-agent/test-setup.sh
git commit -m "test: add integration tests for minimal-agent"
```

---

## Task 13: Create Customer README

**Files:**
- Create: `examples/minimal-agent/README.md`

- [ ] **Step 1: Create README.md**

Create `examples/minimal-agent/README.md`:

```markdown
# Minimal Agent - Example Domain Agent

A reference implementation demonstrating Docker Compose-based deployment for zipsa-runtime agents.

## Overview

This example shows how to package a domain-specific agent with:
- Interactive setup for non-technical users
- Simple start/stop scripts
- MCP server configuration
- Example SKILL integration

## Quick Start

### Prerequisites

- Docker Desktop installed and running
- Git (to clone this repository)

### Setup (First Time)

**Linux/macOS:**
```bash
cd examples/minimal-agent
./setup.sh
```

**Windows:**
```batch
cd examples\minimal-agent
setup.bat
```

Follow the prompts to:
1. Enter your ANTHROPIC_API_KEY
2. (Optional) Configure Google OAuth credentials
3. Select runtime agent (Claude/Codex/Gemini)

### Start the Agent

**Linux/macOS:**
```bash
./start.sh
```

**Windows:**
```batch
start.bat
```

The agent will:
- Initialize MCP servers
- Load the hello-world skill
- Display a chat prompt

### Stop the Agent

**Linux/macOS:**
```bash
./stop.sh
```

**Windows:**
```batch
stop.bat
```

## What's Included

### Files

- `docker-compose.yml` - Container orchestration configuration
- `setup.sh` / `setup.bat` - Interactive setup scripts
- `start.sh` / `start.bat` - Agent startup scripts
- `stop.sh` / `stop.bat` - Agent shutdown scripts
- `skills/hello-world/` - Example SKILL
- `servers.json` - MCP server configuration
- `workspace/` - Your working directory

### Example Skill

The `hello-world` skill demonstrates basic SKILL functionality. Try saying:
- "hello"
- "hi"
- "test the setup"

The agent should respond with a greeting confirming the runtime.

### MCP Servers

Pre-configured MCP servers:
- **time** - Current time and timezone information
- **fetch** - Web fetching capabilities
- **filesystem** - File system access to `/workspace`

## Customization

### Adding Skills

1. Create a new directory in `skills/`
2. Add `skill.md` and `metadata.json`
3. Restart the agent

### Changing MCP Servers

Edit `servers.json` to add/remove MCP servers. See [MCP documentation](https://modelcontextprotocol.io) for available servers.

### Environment Variables

Reconfigure by running setup again:
```bash
./setup.sh  # Linux/macOS
setup.bat   # Windows
```

## Troubleshooting

### "Docker is not installed"

Install Docker Desktop from https://docker.com

### "Docker is not running"

Start Docker Desktop and wait for it to fully initialize.

### "Configuration not found"

Run setup script first:
```bash
./setup.sh  # Linux/macOS
setup.bat   # Windows
```

### "Agent failed to start"

Check logs:
```bash
docker compose logs
```

Common issues:
- Invalid API key (check `.env`)
- Network connectivity (check internet connection)
- Port conflicts (stop other containers)

### Container won't stop

Force stop:
```bash
docker compose down -v  # Removes volumes too
```

## Building Your Own Agent

Use this as a template for your domain agent:

1. Copy this directory structure
2. Replace `minimal-agent` with your agent name
3. Add your domain-specific SKILLs in `skills/`
4. Update MCP servers in `servers.json`
5. Customize README for your users

## Testing

Run integration tests:
```bash
./test-setup.sh
```

## License

MIT License - see main repository LICENSE file
```

- [ ] **Step 2: Verify README formatting**

Run: `head -n 20 examples/minimal-agent/README.md`

Expected: Properly formatted markdown

- [ ] **Step 3: Commit**

```bash
git add examples/minimal-agent/README.md
git commit -m "docs: add customer-facing README for minimal-agent"
```

---

## Task 14: Update Main README

**Files:**
- Modify: `README.md:63-65`

- [ ] **Step 1: Read current README Quick Start section**

Run: `sed -n '45,65p' README.md`

Expected: See current Quick Start section

- [ ] **Step 2: Add Docker Compose section after Usage Examples**

Add after line 125 in `README.md`:

```markdown

---

## Docker Compose Deployment

For production-ready, customer-facing deployments, see the minimal-agent example:

```bash
cd examples/minimal-agent
./setup.sh   # Interactive setup
./start.sh   # Start agent
```

Features:
- ✓ Interactive setup (no Docker knowledge required)
- ✓ Simple start/stop scripts
- ✓ Pre-configured MCP servers
- ✓ Example SKILL included
- ✓ Cross-platform (Linux/macOS/Windows)

**Use this as a template for domain-specific agents.**

See [examples/minimal-agent/README.md](examples/minimal-agent/README.md) for complete documentation.

```

- [ ] **Step 3: Verify README still renders correctly**

Run: `head -n 150 README.md | tail -n 30`

Expected: New section appears correctly

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add Docker Compose deployment section to main README"
```

---

## Task 15: Create CI Workflow

**Files:**
- Create: `.github/workflows/test-compose.yml`

- [ ] **Step 1: Create test-compose.yml**

Create `.github/workflows/test-compose.yml`:

```yaml
name: Test Docker Compose Setup

on:
  push:
    branches: [main, dev/**]
  pull_request:
    branches: [main]

jobs:
  test-minimal-agent:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Run integration tests
        working-directory: examples/minimal-agent
        run: |
          # Make scripts executable
          chmod +x setup.sh start.sh stop.sh test-setup.sh

          # Run integration tests
          ./test-setup.sh

      - name: Validate docker-compose.yml
        working-directory: examples/minimal-agent
        run: |
          docker compose config

      - name: Test setup script (dry run)
        working-directory: examples/minimal-agent
        run: |
          # Automated setup with test credentials
          echo -e "sk-test-key-for-ci\nn\n1\n" | ./setup.sh

          # Verify .env was created
          test -f .env

          # Verify contents
          grep -q "ANTHROPIC_API_KEY=sk-test-key-for-ci" .env
          grep -q "RUNTIME_AGENT=claude" .env

      - name: Clean up
        working-directory: examples/minimal-agent
        if: always()
        run: |
          rm -f .env
```

- [ ] **Step 2: Verify workflow syntax**

Run: `cat .github/workflows/test-compose.yml | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)"`

Expected: No YAML syntax errors

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/test-compose.yml
git commit -m "ci: add Docker Compose integration tests to CI"
```

---

## Task 16: End-to-End Manual Verification

**Files:**
- Test: All scripts and workflows

- [ ] **Step 1: Clean test environment**

```bash
cd examples/minimal-agent
rm -f .env
docker compose down -v 2>/dev/null || true
```

- [ ] **Step 2: Run setup.sh interactively**

Run: `./setup.sh`

Manual test:
1. Enter test API key: `sk-test-manual-verification`
2. Skip Google OAuth: `n`
3. Select Claude: `1`

Expected: `.env` file created, image pulled

- [ ] **Step 3: Verify .env contents**

Run: `cat .env`

Expected:
```
ANTHROPIC_API_KEY=sk-test-manual-verification
RUNTIME_AGENT=claude
```

- [ ] **Step 4: Run integration tests**

Run: `./test-setup.sh`

Expected: All tests pass

- [ ] **Step 5: Test docker-compose config**

Run: `docker compose config`

Expected: No errors, config displayed

- [ ] **Step 6: Clean up test artifacts**

```bash
rm -f .env
docker compose down -v 2>/dev/null || true
cd ../..
```

- [ ] **Step 7: Run CI workflow locally (optional)**

Run: `act -j test-minimal-agent` (if `act` is installed)

Expected: CI tests pass locally

- [ ] **Step 8: Final commit**

```bash
git add -A
git commit -m "chore: verify minimal-agent end-to-end workflow"
```

---

## Self-Review Checklist

### Spec Coverage

✓ **Example Domain Agent** - Tasks 1-13 create complete `examples/minimal-agent/`
✓ **All Scripts** - Tasks 6-11 create setup/start/stop for Linux/macOS/Windows
✓ **docker-compose.yml** - Task 2
✓ **Integration Tests** - Task 12
✓ **Customer README** - Task 13
✓ **Main README Update** - Task 14
✓ **CI/CD Integration** - Task 15

### Placeholder Scan

No TBD, TODO, or placeholders found. All code blocks contain complete implementations.

### Type Consistency

- Environment variable names consistent: `ANTHROPIC_API_KEY`, `RUNTIME_AGENT`, `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`
- File paths consistent: `examples/minimal-agent/`, `skills/hello-world/`, `servers.json`
- Script names consistent: `setup.sh`, `start.sh`, `stop.sh` (and `.bat` equivalents)
- Service name consistent: `minimal-agent`
- Volume name consistent: `minimal-agent-config`

### Task Dependencies

1. Task 1 → Creates directory structure
2. Tasks 2-5 → Create core configuration files
3. Tasks 6-11 → Create executable scripts (depend on Tasks 2-5)
4. Task 12 → Integration tests (depend on all previous tasks)
5. Task 13 → Documentation (depends on all features)
6. Task 14 → Main README (depends on Task 13)
7. Task 15 → CI workflow (depends on Task 12)
8. Task 16 → End-to-end verification (depends on all tasks)

All dependencies are properly ordered.

---

## Execution Notes

- Each task is designed for 2-5 minute execution
- All scripts include error handling and user feedback
- Integration tests validate each component
- CI workflow ensures ongoing quality
- Manual verification step confirms end-to-end functionality

Total estimated time: ~2 hours for complete implementation
