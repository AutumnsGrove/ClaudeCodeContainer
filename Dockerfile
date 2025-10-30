# Production-ready Dockerfile for Claude Code Container Environment
# Base: Ubuntu 24.04 LTS for stability and long-term support

FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set locale to avoid encoding issues
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install essential system packages and development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    # Build tools
    build-essential \
    gcc \
    g++ \
    make \
    # Version control
    git \
    # Python 3.12 and dependencies
    python3 \
    python3-venv \
    python3-dev \
    python3-pip \
    # Additional utilities
    vim \
    nano \
    less \
    tree \
    jq \
    zip \
    unzip \
    # Networking tools
    iputils-ping \
    netcat-traditional \
    # Process monitoring
    procps \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Create symlinks for python/pip to use Python 3.12
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Install Node.js 20.x LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install UV package manager for Python
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx

# Create non-root user 'claude' (system assigns UID automatically)
RUN useradd -m -s /bin/bash claude && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up workspace directory structure
RUN mkdir -p /workspace/Projects \
             /workspace/Documentation \
             /workspace/Research \
             /workspace/shared \
             /workspace/exports \
             /workspace/imports && \
    chown -R claude:claude /workspace

# Configure Git with sensible defaults
RUN git config --system user.name "Claude Code" && \
    git config --system user.email "claude@anthropic.com" && \
    git config --system init.defaultBranch main && \
    git config --system core.editor vim && \
    git config --system pull.rebase false && \
    git config --system core.autocrlf input

# Install Claude Code CLI from GitHub releases (optional - non-fatal if unavailable)
# Note: If installation fails, Claude CLI can be installed manually later
RUN CLAUDE_VERSION="0.1.13" && \
    ARCH="$(uname -m)" && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="x64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    (wget -q "https://github.com/anthropics/anthropic-cli/releases/download/v${CLAUDE_VERSION}/claude-${CLAUDE_VERSION}-linux-${ARCH}.tar.gz" -O /tmp/claude.tar.gz && \
    tar -xzf /tmp/claude.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/claude && \
    rm /tmp/claude.tar.gz && \
    echo "Claude CLI ${CLAUDE_VERSION} installed successfully") || \
    echo "Claude CLI installation skipped - binary not available for this architecture. Install manually if needed."

# Set up Python environment for UV
ENV UV_SYSTEM_PYTHON=1 \
    UV_CACHE_DIR=/home/claude/.cache/uv \
    PATH="/home/claude/.local/bin:${PATH}"

# Set environment variables for better container behavior
ENV TERM=xterm-256color \
    SHELL=/bin/bash \
    USER=claude \
    HOME=/home/claude

# Copy BaseProject and house-agents configuration files
# These will be installed on first container run
USER root
COPY container-config /opt/claude-config
RUN chmod +x /opt/claude-config/first-run.sh && \
    chown -R claude:claude /opt/claude-config
USER claude

# Create user-level directories
RUN mkdir -p /home/claude/.config \
             /home/claude/.cache \
             /home/claude/.local/bin

# Set working directory
WORKDIR /workspace

# Add healthcheck to verify container is functioning
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python --version && node --version && git --version || exit 1

# Default command: run first-run setup, then start bash shell
CMD ["/bin/bash", "-c", "/opt/claude-config/first-run.sh && exec /bin/bash"]

# Labels for metadata
LABEL maintainer="Claude Code Container Project" \
      description="Production-ready container environment for Claude Code with BaseProject workflows" \
      version="1.0.1" \
      org.opencontainers.image.source="https://github.com/AutumnsGrove/ClaudeCodeContainer"
