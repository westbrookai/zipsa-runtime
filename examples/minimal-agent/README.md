# Zipsa Runtime: Minimal Agent Example

Get started with Docker Compose in 5 minutes.

---

## Overview

This example demonstrates how to run Claude Code in a pre-configured Docker environment using Docker Compose. No manual Docker commands needed - just one script to set up everything.

**What you get:**
- Claude Code ready to run
- MCP servers pre-configured
- Volume mounts for your workspace
- Environment variables managed via `.env`

---

## Quick Start

### 1. Run Setup Script

```bash
cd examples/minimal-agent
./setup.sh
```

This script will:
1. Create `.env` file (if missing)
2. Prompt for your `ANTHROPIC_API_KEY`
3. Start the container with `docker compose up`

### 2. Verify Installation

```bash
# Check containers are running
docker compose ps

# Test Claude Code
docker compose exec agent claude --version
```

### 3. Start Using Claude Code

```bash
# Interactive session
docker compose exec agent claude

# Run a specific command
docker compose exec agent claude "Analyze this codebase"
```

---

## What's Included

### Files in This Directory

```
examples/minimal-agent/
├── README.md              # This file
├── docker-compose.yml     # Container configuration
├── setup.sh               # One-command setup script
├── .env.example           # Template for environment variables
└── workspace/             # Your project files (mounted volume)
```

### Pre-configured Features

1. **Claude Code**: Official Anthropic CLI pre-installed
2. **MCP Servers**: Time and Fetch servers configured
3. **Workspace Volume**: `./workspace` mounted to `/workspace` in container
4. **Auto-restart**: Container restarts automatically on failures

---

## Customization

### Adding More MCP Servers

Edit `docker-compose.yml` to add more MCP servers:

```yaml
services:
  agent:
    environment:
      - MCP_SERVERS=time,fetch,filesystem  # Add more servers
    volumes:
      - ./workspace:/workspace
      - ./custom-servers.json:/app/servers.json  # Custom MCP config
```

### Changing the Workspace Directory

```yaml
volumes:
  - /path/to/your/project:/workspace  # Use absolute path
```

### Using Different API Keys

Edit `.env` file:

```bash
ANTHROPIC_API_KEY=sk-ant-your-new-key-here
GOOGLE_OAUTH_CLIENT_ID=optional-google-id
GOOGLE_OAUTH_CLIENT_SECRET=optional-google-secret
```

Then restart:

```bash
docker compose restart
```

---

## Troubleshooting

### Issue: "ANTHROPIC_API_KEY not set"

**Solution:**
```bash
# Re-run setup script
./setup.sh

# Or manually edit .env
nano .env
docker compose restart
```

### Issue: Container exits immediately

**Check logs:**
```bash
docker compose logs agent
```

**Common causes:**
- Invalid API key
- Missing `.env` file
- Port conflicts

**Solution:**
```bash
# Recreate container
docker compose down
docker compose up --force-recreate
```

### Issue: Claude Code command not found

**Verify installation:**
```bash
docker compose exec agent which claude
docker compose exec agent claude --version
```

**Solution:**
```bash
# Rebuild image
docker compose build --no-cache
docker compose up
```

### Issue: Permission denied in workspace

**Problem:** File ownership mismatch

**Solution:**
```bash
# Fix permissions (run from host)
sudo chown -R $(id -u):$(id -g) ./workspace

# Or run container as current user (add to docker-compose.yml)
user: "${UID}:${GID}"
```

---

## Building Your Own Agent

### Step 1: Copy This Example

```bash
cp -r examples/minimal-agent my-custom-agent
cd my-custom-agent
```

### Step 2: Customize `docker-compose.yml`

```yaml
services:
  agent:
    image: ghcr.io/westbrookai/zipsa-runtime:latest
    container_name: my-agent
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - CUSTOM_VAR=${CUSTOM_VAR}  # Add your vars
    volumes:
      - ./my-workspace:/workspace
      - ./my-servers.json:/app/servers.json
```

### Step 3: Add Custom MCP Servers

Create `my-servers.json`:

```json
{
  "mcpServers": {
    "time": {
      "command": "uvx",
      "args": ["mcp-server-time"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    }
  }
}
```

### Step 4: Run Your Agent

```bash
./setup.sh
docker compose exec agent claude
```

---

## Testing

### Manual Tests

```bash
# 1. Verify container is running
docker compose ps

# 2. Test Claude Code
docker compose exec agent claude --version

# 3. Test MCP servers
docker compose exec agent claude "What time is it?"

# 4. Test workspace access
docker compose exec agent ls -la /workspace
```

### Automated Tests (Optional)

Create `test.sh`:

```bash
#!/bin/bash
set -e

echo "Testing minimal-agent setup..."

# Test 1: Container running
docker compose ps | grep -q "Up" || exit 1

# Test 2: Claude Code installed
docker compose exec -T agent claude --version || exit 1

# Test 3: Workspace mounted
docker compose exec -T agent test -d /workspace || exit 1

echo "All tests passed!"
```

Run tests:
```bash
chmod +x test.sh
./test.sh
```

---

## License

MIT License - see [LICENSE](../../LICENSE) file for details.

---

## Next Steps

1. Read the [main README](../../README.md) for more advanced usage
2. Explore [MCP server documentation](https://modelcontextprotocol.io)
3. Check [Claude Code docs](https://github.com/anthropics/claude-code)
4. Build your own custom agent configurations

---

**Need Help?**
- GitHub Issues: https://github.com/westbrookai/zipsa-runtime/issues
- Documentation: [CLAUDE.md](../../CLAUDE.md)
