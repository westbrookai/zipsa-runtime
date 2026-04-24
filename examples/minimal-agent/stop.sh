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
