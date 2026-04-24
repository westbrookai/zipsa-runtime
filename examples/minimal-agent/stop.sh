#!/bin/bash
# ============================================================================
# Stop Script for Minimal Agent (Linux/macOS)
# ============================================================================
#
# This script stops the running minimal-agent Docker container.
#
# Usage: ./stop.sh
# ============================================================================

set -e  # Exit on error

echo "============================================================================"
echo "Stopping Minimal Agent"
echo "============================================================================"
echo

# Check if container exists and is running
if docker ps --format '{{.Names}}' | grep -q '^minimal-agent$'; then
    echo "[INFO] Stopping container..."
    docker stop minimal-agent
    echo "[OK] Container stopped"
else
    echo "[INFO] Container 'minimal-agent' is not running"
fi

echo
