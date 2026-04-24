#!/bin/bash
# ============================================================================
# Start Script for Minimal Agent (Linux/macOS)
# ============================================================================
#
# This script starts the minimal-agent Docker container with:
# - Environment variables from .env file
# - Port mapping from .env
# - Detached mode (runs in background)
# - Auto-restart on failure
# - Container name for easy management
#
# Usage: ./start.sh
# ============================================================================

set -e  # Exit on error

echo "============================================================================"
echo "Starting Minimal Agent"
echo "============================================================================"
echo

# Check if .env file exists
if [ ! -f .env ]; then
    echo "[ERROR] .env file not found"
    echo "Please run ./setup.sh first"
    exit 1
fi

# Load .env file
source .env

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^minimal-agent$'; then
    echo "[INFO] Container 'minimal-agent' already exists"

    # Check if it's running
    if docker ps --format '{{.Names}}' | grep -q '^minimal-agent$'; then
        echo "[INFO] Container is already running"
        echo
        echo "Agent is available at: http://localhost:${PORT}"
        exit 0
    fi

    echo "[INFO] Starting existing container..."
    docker start minimal-agent
else
    echo "[INFO] Creating and starting new container..."
    docker run -d \
        --name minimal-agent \
        --env-file .env \
        -p "${PORT}:3000" \
        --restart unless-stopped \
        minimal-agent
fi

echo
echo "============================================================================"
echo "Agent Started Successfully"
echo "============================================================================"
echo
echo "Agent is available at: http://localhost:${PORT}"
echo
echo "Useful commands:"
echo "  View logs:  docker logs minimal-agent"
echo "  Stop agent: ./stop.sh"
echo
