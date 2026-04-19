# SKILL Runtime Docker Image
# Base: Debian Slim for glibc compatibility
# Purpose: Runtime environment for Claude Code, Codex, OpenClaw with MCP support

FROM debian:bookworm-slim

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="SKILL Runtime with Claude Code, Codex, and OpenClaw"
LABEL version="0.1.0"

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /workspace

# Install system dependencies in a single layer
# - curl: for downloading installers
# - ca-certificates: for HTTPS connections
# - git: required by many tools
# - build-essential: C compiler for native modules
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \
        build-essential \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 24.x (for npx, npm, and OpenClaw support)
# Using NodeSource official repository
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Verify Node.js installation
RUN node --version && npm --version && npx --version

# Install Python 3.11+ (Debian Bookworm comes with Python 3.11)
# Install pip and setuptools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create symlinks for python and pip (python3 -> python)
RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# Add local bin to PATH first (for uv and pipx)
ENV PATH="/root/.local/bin:${PATH}"

# Install uv (modern Python package installer)
# uv provides uvx command for running Python tools
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv --version && uvx --version

# Install pipx (for installing Python CLI tools in isolated environments)
# Using apt instead of pip to avoid PEP 668 externally-managed-environment error
RUN apt-get update && \
    apt-get install -y --no-install-recommends pipx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pipx ensurepath && \
    pipx --version

# Install Claude Code (official Anthropic CLI)
# Using npm global install
RUN npm install -g @anthropic-ai/claude-code && \
    npm cache clean --force

# Verify Claude Code installation
RUN claude --version

# Install Codex (OpenAI's coding agent)
# Install via npm global
RUN npm install -g @openai/codex || echo "Codex installation skipped (package may require access)" && \
    npm cache clean --force

# Install OpenClaw (open-source agent framework)
# Install via npm global if available, or pipx as fallback
RUN npm install -g openclaw || pipx install openclaw || echo "OpenClaw installation skipped (package may not exist yet)"

# Create workspace directory if it doesn't exist
RUN mkdir -p /workspace

# Set environment variables for better CLI experience
ENV TERM=xterm-256color
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Add helpful aliases (optional)
RUN echo 'alias ll="ls -lah"' >> /root/.bashrc && \
    echo 'alias claude-help="claude --help"' >> /root/.bashrc

# Health check (optional - checks if Node.js is responsive)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node --version || exit 1

# Default command: show help
CMD ["claude", "--help"]
