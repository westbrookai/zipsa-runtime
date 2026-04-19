# SKILL Runtime Docker Image
# Base: Debian Slim for glibc compatibility
# Purpose: Runtime environment for Claude Code, Codex, OpenClaw with MCP support

FROM debian:bookworm-slim

#-----------------------------------------------------------
# Build Arguments - Package Versions
# Update these versions to pin specific package versions
#-----------------------------------------------------------

# System packages (apt)
ARG CURL_VERSION="7.88.1-10+deb12u14"
ARG CA_CERTIFICATES_VERSION="20230311+deb12u1"
ARG GIT_VERSION="1:2.39.5-0+deb12u3"
ARG BUILD_ESSENTIAL_VERSION="12.9"
ARG NODEJS_VERSION="24.14.1-1nodesource1"
ARG PYTHON3_VERSION="3.11.2-1+b1"
ARG PYTHON3_PIP_VERSION="23.0.1+dfsg-1"
ARG PYTHON3_VENV_VERSION="3.11.2-1+b1"
ARG PIPX_VERSION="1.1.0-1"

# NPM packages
ARG CLAUDE_CODE_VERSION="2.1.114"
ARG CODEX_VERSION="0.121.0"
ARG GEMINI_CLI_VERSION="0.32.1"

#-----------------------------------------------------------
# Container Configuration
#-----------------------------------------------------------

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="SKILL Runtime with Claude Code, Codex, and Gemini CLI"
LABEL version="0.2.0"

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Set shell to use pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set working directory
WORKDIR /workspace

#-----------------------------------------------------------
# System Dependencies Installation
#-----------------------------------------------------------

# Install system dependencies in a single layer
# - curl: for downloading installers
# - ca-certificates: for HTTPS connections
# - git: required by many tools
# - build-essential: C compiler for native modules
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl=${CURL_VERSION} \
        ca-certificates=${CA_CERTIFICATES_VERSION} \
        git=${GIT_VERSION} \
        build-essential=${BUILD_ESSENTIAL_VERSION} \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 24.x (for npx, npm, and OpenClaw support)
# Using NodeSource official repository
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y --no-install-recommends nodejs=${NODEJS_VERSION} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Verify Node.js installation
RUN node --version && npm --version && npx --version

#-----------------------------------------------------------
# Python Installation
#-----------------------------------------------------------

# Install Python 3.11+ (Debian Bookworm comes with Python 3.11)
# Install pip and setuptools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3=${PYTHON3_VERSION} \
        python3-pip=${PYTHON3_PIP_VERSION} \
        python3-venv=${PYTHON3_VENV_VERSION} \
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
    apt-get install -y --no-install-recommends pipx=${PIPX_VERSION} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pipx ensurepath && \
    pipx --version

#-----------------------------------------------------------
# Agent Runtimes Installation
#-----------------------------------------------------------

# Install Claude Code (official Anthropic CLI)
# Using npm global install with --omit=dev to exclude devDependencies
RUN npm install -g --omit=dev @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} && \
    npm cache clean --force

# Verify Claude Code installation
RUN claude --version

# Install Codex (OpenAI's coding agent)
# Install via npm global with --omit=dev
RUN npm install -g --omit=dev @openai/codex@${CODEX_VERSION} || echo "Codex installation skipped (package may require access)" && \
    npm cache clean --force

# Install Gemini CLI (Google's Gemini agent)
# Install via npm global with --omit=dev
RUN npm install -g --omit=dev @google/gemini-cli@${GEMINI_CLI_VERSION} && \
    npm cache clean --force

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
