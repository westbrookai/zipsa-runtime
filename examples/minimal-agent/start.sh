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
