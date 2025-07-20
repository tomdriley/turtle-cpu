# Use the official Python Dev Container base image
FROM mcr.microsoft.com/devcontainers/python:3.11

# Install system-level and RTL development dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    pipx \
    python3-venv \
    git \
    wget \
    make \
    x11-apps \
    xterm \
    gedit \
    tree \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Set up pipx environment
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIPX_HOME=/usr/local/pipx

# Install poetry via pipx
RUN pipx install poetry

# Optional: Pre-pull Docker images for RTL development (commented out to avoid image bloat)
# RUN docker pull verilator/verilator:v5.036 || true

# Optional: Set environment variables (e.g., for GUI apps)
# ENV DISPLAY=:1
