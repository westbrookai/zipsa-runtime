# SKILL Runtime Docker Image - Multi-stage Build
# Base: Debian Slim for glibc compatibility
# Purpose: Runtime environment for Claude Code, Codex, Gemini CLI with MCP support
# Strategy: Build stage for npm packages, runtime stage without build-essential

#-----------------------------------------------------------
# Build Arguments - Package Versions
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
# Stage 1: Builder - Install packages with build tools
#-----------------------------------------------------------

FROM debian:bookworm-slim AS builder

# Reuse ARG declarations in this stage
ARG CURL_VERSION
ARG CA_CERTIFICATES_VERSION
ARG BUILD_ESSENTIAL_VERSION
ARG NODEJS_VERSION
ARG CLAUDE_CODE_VERSION
ARG CODEX_VERSION
ARG GEMINI_CLI_VERSION

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Set shell to use pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl=${CURL_VERSION} \
        ca-certificates=${CA_CERTIFICATES_VERSION} \
        build-essential=${BUILD_ESSENTIAL_VERSION} \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 24.x
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y --no-install-recommends nodejs=${NODEJS_VERSION} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install npm packages globally
# These will be copied to the runtime stage
RUN npm install -g --omit=dev @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} && \
    npm cache clean --force

RUN npm install -g --omit=dev @openai/codex@${CODEX_VERSION} || echo "Codex installation skipped" && \
    npm cache clean --force

RUN npm install -g --omit=dev @google/gemini-cli@${GEMINI_CLI_VERSION} && \
    npm cache clean --force

# Verify installations in builder stage
RUN claude --version && codex --version && gemini --version

#-----------------------------------------------------------
# Stage 2: Runtime - Minimal dependencies only
#-----------------------------------------------------------

FROM debian:bookworm-slim AS runtime

# Reuse ARG declarations in runtime stage
ARG CURL_VERSION
ARG CA_CERTIFICATES_VERSION
ARG GIT_VERSION
ARG NODEJS_VERSION
ARG PYTHON3_VERSION
ARG PYTHON3_PIP_VERSION
ARG PYTHON3_VENV_VERSION
ARG PIPX_VERSION

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="SKILL Runtime with Claude Code, Codex, and Gemini CLI (Multi-stage)"
LABEL version="0.3.0"

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Set shell to use pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set working directory
WORKDIR /workspace

# Install runtime dependencies (NO build-essential)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl=${CURL_VERSION} \
        ca-certificates=${CA_CERTIFICATES_VERSION} \
        git=${GIT_VERSION} \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 24.x (runtime only, no build tools)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y --no-install-recommends nodejs=${NODEJS_VERSION} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy installed npm packages from builder stage
# npm installs to /usr (not /usr/local) on Debian
# Copy entire node_modules to preserve all dependencies
COPY --from=builder /usr/lib/node_modules/@anthropic-ai /usr/lib/node_modules/@anthropic-ai
COPY --from=builder /usr/lib/node_modules/@openai /usr/lib/node_modules/@openai
COPY --from=builder /usr/lib/node_modules/@google /usr/lib/node_modules/@google

# Recreate symlinks in runtime (instead of copying broken symlinks)
# These match the symlinks created by npm install -g
RUN ln -sf ../lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe /usr/bin/claude && \
    ln -sf ../lib/node_modules/@openai/codex/bin/codex.js /usr/bin/codex && \
    ln -sf ../lib/node_modules/@google/gemini-cli/dist/index.js /usr/bin/gemini

# Verify Node.js and agent tools are available
RUN node --version && npm --version && npx --version
RUN claude --version && codex --version && gemini --version

# Install Python 3.11+ (runtime only)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3=${PYTHON3_VERSION} \
        python3-pip=${PYTHON3_PIP_VERSION} \
        python3-venv=${PYTHON3_VENV_VERSION} \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create symlinks for python and pip
RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# Add local bin to PATH first (for uv and pipx)
ENV PATH="/root/.local/bin:${PATH}"

# Install uv (modern Python package installer)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv --version && uvx --version

# Install pipx (for isolated Python CLI tools)
RUN apt-get update && \
    apt-get install -y --no-install-recommends pipx=${PIPX_VERSION} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pipx ensurepath && \
    pipx --version

# Create workspace directory
RUN mkdir -p /workspace

# Set environment variables for better CLI experience
ENV TERM=xterm-256color
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Add helpful aliases
RUN echo 'alias ll="ls -lah"' >> /root/.bashrc && \
    echo 'alias claude-help="claude --help"' >> /root/.bashrc

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node --version || exit 1

# Default command
CMD ["claude", "--help"]
