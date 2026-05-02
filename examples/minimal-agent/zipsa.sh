#!/bin/bash
# zipsa.sh — minimal skill runner with MCP support (POC v0.2)
# Usage: ./zipsa.sh <skill_name> "<user_input>"
# Env: DRY_RUN=1 for dry-run mode

set -euo pipefail

SKILL_NAME="${1:?Usage: $0 <skill_name> \"<user_input>\"}"
USER_INPUT="${2:?Usage: $0 <skill_name> \"<user_input>\"}"

SKILL_DIR="./skills/${SKILL_NAME}"
MANIFEST="${SKILL_DIR}/manifest.yaml"
SKILL_MD="${SKILL_DIR}/SKILL.md"

if [[ ! -f "$MANIFEST" ]]; then
  echo "Skill not found: $SKILL_NAME (looked in $SKILL_DIR)" >&2
  exit 1
fi

# === Extract metadata from manifest ===
NAME=$(yq '.metadata.name' "$MANIFEST")
VERSION=$(yq '.metadata.version' "$MANIFEST")
PURPOSE=$(yq '.spec.purpose' "$MANIFEST")

# Tool whitelist (builtin + mcp)
BUILTIN_TOOLS=$(yq '.spec.tools.builtin // [] | join(",")' "$MANIFEST")
# Convert "name:method" -> "mcp__name__method"
MCP_TOOLS=$(yq '.spec.tools.mcp // [] | map("mcp__" + sub(":"; "__")) | join(",")' "$MANIFEST")

if [[ -n "$BUILTIN_TOOLS" && -n "$MCP_TOOLS" ]]; then
  ALLOWED_TOOLS="${BUILTIN_TOOLS},${MCP_TOOLS}"
elif [[ -n "$BUILTIN_TOOLS" ]]; then
  ALLOWED_TOOLS="$BUILTIN_TOOLS"
elif [[ -n "$MCP_TOOLS" ]]; then
  ALLOWED_TOOLS="$MCP_TOOLS"
else
  ALLOWED_TOOLS=""
fi

# === Build MCP config from manifest ===
MCP_COUNT=$(yq '.spec.mcp // [] | length' "$MANIFEST")

# Volume mounts that need to happen (host:container:mode)
declare -a EXTRA_MOUNTS=()

# MCP config JSON (Claude Code's --mcp-config format)
MCP_CONFIG="$(pwd)/.zipsa-mcp-$$.json"

echo '{"mcpServers":{}}' > "$MCP_CONFIG"

if [[ "$MCP_COUNT" -gt 0 ]]; then
  for i in $(seq 0 $((MCP_COUNT - 1))); do
    MCP_NAME=$(yq ".spec.mcp[$i].name" "$MANIFEST")
    MCP_TYPE=$(yq ".spec.mcp[$i].type" "$MANIFEST")

    if [[ "$MCP_TYPE" == "stdio" ]]; then
      # Handle mount declaration
      MOUNT_HOST=$(yq ".spec.mcp[$i].mount.host // \"\"" "$MANIFEST")
      MOUNT_CONTAINER=$(yq ".spec.mcp[$i].mount.container // \"\"" "$MANIFEST")
      MOUNT_MODE=$(yq ".spec.mcp[$i].mount.mode // \"ro\"" "$MANIFEST")

      if [[ -n "$MOUNT_HOST" && -n "$MOUNT_CONTAINER" ]]; then
        # Expand tilde manually
        MOUNT_HOST_EXPANDED="${MOUNT_HOST/#\~/$HOME}"
        EXTRA_MOUNTS+=("-v" "${MOUNT_HOST_EXPANDED}:${MOUNT_CONTAINER}:${MOUNT_MODE}")
      fi

      RUNTIME=$(yq ".spec.mcp[$i].runtime" "$MANIFEST")
      PACKAGE=$(yq ".spec.mcp[$i].package" "$MANIFEST")
      MCP_ARGS=$(yq -o=json ".spec.mcp[$i].args // []" "$MANIFEST")

      # For Node.js stdio MCP: use npx (assumes node/npx in container)
      if [[ "$RUNTIME" == "node" ]]; then
        CMD_JSON=$(jq -n \
          --arg pkg "$PACKAGE" \
          --argjson args "$MCP_ARGS" \
          '{command: "npx", args: (["-y", $pkg] + $args)}')
      else
        echo "Unsupported stdio runtime: $RUNTIME" >&2
        exit 1
      fi

      jq --arg name "$MCP_NAME" --argjson cmd "$CMD_JSON" \
        '.mcpServers[$name] = $cmd' "$MCP_CONFIG" > "${MCP_CONFIG}.tmp" \
        && mv "${MCP_CONFIG}.tmp" "$MCP_CONFIG"

    elif [[ "$MCP_TYPE" == "http" ]]; then
      MCP_URL=$(yq ".spec.mcp[$i].url" "$MANIFEST")

      # For HTTP MCP, OAuth tokens come from the host's
      # claude.ai-managed credentials (already mounted via credentials.json).
      jq --arg name "$MCP_NAME" --arg url "$MCP_URL" \
        '.mcpServers[$name] = {type: "http", url: $url}' "$MCP_CONFIG" > "${MCP_CONFIG}.tmp" \
        && mv "${MCP_CONFIG}.tmp" "$MCP_CONFIG"
    fi
  done
fi

INSTRUCTIONS=$(cat "$SKILL_MD")

# === Compose system prompt ===
SYSTEM_PROMPT="You are the ${NAME} agent (v${VERSION}).

# Purpose
${PURPOSE}

# Instructions
${INSTRUCTIONS}

# Available tools
You may ONLY use these tools: ${ALLOWED_TOOLS}
If a task requires other tools, refuse politely.

# Behavior rules
- Single-task focused: only do what your purpose describes
- Be concise: no preamble, just answer
- Decline gracefully for off-topic requests"

# === Build Docker command ===
CMD=(
  docker
  run
  --name "zipsa-${SKILL_NAME}-$$"
  --rm
  -e CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN"
  -v "$(pwd)/credentials.json:/home/agent/.claude/.credentials.json"
  -v "$(pwd)/workspace:/workspace"
  -v "$(pwd)/claude.json:/home/agent/.claude.json:ro"
  -v "${MCP_CONFIG}:/tmp/mcp.json:ro"
)

# Append extra mounts
CMD+=(${EXTRA_MOUNTS[@]+"${EXTRA_MOUNTS[@]}"})

# Claude command inside container
CLAUDE_CMD=(
  claude
  --print "$USER_INPUT"
  --append-system-prompt "$SYSTEM_PROMPT"
  --allowedTools "$ALLOWED_TOOLS"
  --mcp-config /tmp/mcp.json
  --dangerously-skip-permissions
  --output-format=stream-json
  --verbose
)

# Bash command inside container
BASH_CMD=(bash)

cleanup() {
  rm -f "$MCP_CONFIG"
}

mask_value() {
  local val="$1"
  local prefix_len=6

  if [ ${#val} -le $prefix_len ]; then
    echo "$val"
  else
    echo "${val:0:$prefix_len}..."
  fi
}


print_dry_run() {
  echo "=== DRY RUN ==="
  echo "Skill: ${NAME} v${VERSION}"
  echo "Allowed tools: ${ALLOWED_TOOLS}"
  echo
  echo "MCP config (${MCP_CONFIG}):"
  jq . "$MCP_CONFIG"
  echo
  echo "Docker command:"
  for i in "${!CMD[@]}"; do
    arg="${CMD[$i]}"

    # Mask environment variables
    if [[ "$arg" == CLAUDE_CODE_OAUTH_TOKEN=* ]]; then
      key="${arg%%=*}"
      val="${arg#*=}"
      masked_val=$(mask_value "$val")
      printf "  [%2d] %s=%s\n" "$i" "$key" "$masked_val"
    else
      printf "  [%2d] %s\n" "$i" "$arg"
    fi
  done
}

print_bash_run() {
  echo "=== BASH RUN ==="
  echo "MCP config: /tmp/mcp.json"
  echo "Sessions: /host-claude-projects/ (if mounted)"
  echo "Exit with Ctrl+D or 'exit'"
  echo
}

# === Execute or dry-run ===
if [[ "${DRY_RUN:-0}" == "1" ]]; then
  CMD+=("ghcr.io/westbrookai/zipsa-runtime:latest")
  CMD+=("${CLAUDE_CMD[@]}")
  print_dry_run
elif [[ "${BASH_RUN:-0}" == "1" ]]; then
  # Insert -it before image (interactive shell needs TTY)
  CMD=("${CMD[@]:0:2}" "-it" "${CMD[@]:2}")
  CMD+=("ghcr.io/westbrookai/zipsa-runtime:latest")
  CMD+=("${BASH_CMD[@]}")
  print_bash_run
  trap cleanup EXIT
  "${CMD[@]}"
else
  CMD+=("ghcr.io/westbrookai/zipsa-runtime:latest")
  CMD+=("${CLAUDE_CMD[@]}")
  trap cleanup EXIT
  "${CMD[@]}"
fi
