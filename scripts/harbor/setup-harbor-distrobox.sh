#!/usr/bin/env bash
#
# Copyright (c) 2025 Peter H. Boling
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# setup-harbor-distrobox.sh
#
# Creates a distrobox environment with harbor (Terminal Bench) installed via uv.
# Can be used to create multiple named distroboxes for discrete experiments.
#
# Usage:
#   ./setup-harbor-distrobox.sh [OPTIONS]
#
# Options:
#   -n, --name NAME      Name for the distrobox (default: harbor-exp)
#   -i, --image IMAGE    Base image to use (default: ubuntu:24.04)
#   -H, --home PATH      Custom home directory for the distrobox (default: ~/.distrobox-homes/<name>)
#   -u, --user USER      Non-root username to create inside the distrobox (default: host $USER)
#   --no-root            Create rootless container (default is rootful for Docker-in-Docker)
#   -d, --delete         Delete existing distrobox with the same name first
#   --no-direnv          Skip direnv installation (direnv is installed by default for .envrc support)
#   --no-mise            Skip mise installation (mise is installed by default for language management)
#   -h, --help           Show this help message
#
# Note: Rootful is the default because harbor tasks require Docker-in-Docker,
#       which needs root access on atomic distros like Bazzite/Fedora Silverblue.
#
# Note: Each distrobox gets an isolated home directory at ~/.distrobox-homes/<name>
#       to prevent host dotfiles from leaking in and causing conflicts.
#
# Installs:
#   - Docker CE (for rootful containers only - required for harbor tasks)
#   - uv (Python package manager)
#   - Python 3.13 (3.14 blocked by missing obstore cp314 wheels)
#   - harbor (Terminal Bench CLI via uv tool)
#   - direnv (for .envrc support with API keys & credentials) [unless --no-direnv]
#   - mise (for managing other programming languages) [unless --no-mise]
#
# Examples:
#   ./setup-harbor-distrobox.sh                           # Create rootful 'harbor-exp' distrobox
#   ./setup-harbor-distrobox.sh -n experiment-1           # Create rootful 'experiment-1' distrobox
#   ./setup-harbor-distrobox.sh -n experiment-1 -d        # Delete and recreate 'experiment-1'
#   ./setup-harbor-distrobox.sh -n test --no-root         # Create rootless container (no Docker)
#   ./setup-harbor-distrobox.sh --no-direnv --no-mise     # Skip direnv and mise installation
#   ./setup-harbor-distrobox.sh -n test -H ~/my-home      # Use custom home directory

set -euo pipefail

# Default values
DISTROBOX_NAME="harbor-exp"
BASE_IMAGE="ubuntu:24.04"
CUSTOM_HOME=""  # Empty means use default: ~/.distrobox-homes/<name>
ROOTFUL=true
DELETE_EXISTING=false
INSTALL_DIRENV=true
INSTALL_MISE=true
DISTROBOX_USER="${USER}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    head -35 "$0" | grep -E '^#' | sed 's/^# \?//'
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            DISTROBOX_NAME="$2"
            shift 2
            ;;
        -i|--image)
            BASE_IMAGE="$2"
            shift 2
            ;;
        -H|--home)
            CUSTOM_HOME="$2"
            shift 2
            ;;
        -u|--user)
            DISTROBOX_USER="$2"
            shift 2
            ;;
        -d|--delete)
            DELETE_EXISTING=true
            shift
            ;;
        --no-root)
            ROOTFUL=false
            shift
            ;;
        --no-direnv)
            INSTALL_DIRENV=false
            shift
            ;;
        --no-mise)
            INSTALL_MISE=false
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            ;;
    esac
done

log_info "Setting up distrobox: ${DISTROBOX_NAME}"
log_info "Base image: ${BASE_IMAGE}"
log_info "Rootful: ${ROOTFUL}"
if [[ -n "${CUSTOM_HOME}" ]]; then
    log_info "Custom home: ${CUSTOM_HOME}"
fi
log_info "Install direnv: ${INSTALL_DIRENV}"
log_info "Install mise: ${INSTALL_MISE}"
log_info "Distrobox user: ${DISTROBOX_USER}"

# Delete existing distrobox if requested
if [[ "$DELETE_EXISTING" == "true" ]]; then
    log_info "Checking for existing distrobox..."
    # Use custom home if specified, otherwise use default location
    if [[ -n "${CUSTOM_HOME}" ]]; then
        DISTROBOX_HOME_TO_DELETE="${CUSTOM_HOME}"
    else
        DISTROBOX_HOME_TO_DELETE="$HOME/.distrobox-homes/${DISTROBOX_NAME}"
    fi

    if [[ "$ROOTFUL" == "true" ]]; then
        # Check rootful distroboxes
        if distrobox list --root 2>/dev/null | grep -qE "(^|\s)${DISTROBOX_NAME}(\s|$)"; then
            log_warn "Deleting existing rootful distrobox: ${DISTROBOX_NAME}"
            distrobox rm --root --force "${DISTROBOX_NAME}" || true
            # Also clean up the isolated home directory
            if [[ -d "${DISTROBOX_HOME_TO_DELETE}" ]]; then
                log_info "Cleaning up isolated home directory: ${DISTROBOX_HOME_TO_DELETE}"
                rm -rf "${DISTROBOX_HOME_TO_DELETE}"
            fi
            log_success "Deleted existing distrobox"
        else
            log_info "No existing rootful distrobox found with name: ${DISTROBOX_NAME}"
        fi
    else
        # Check regular distroboxes
        if distrobox list 2>/dev/null | grep -qE "(^|\s)${DISTROBOX_NAME}(\s|$)"; then
            log_warn "Deleting existing distrobox: ${DISTROBOX_NAME}"
            distrobox rm --force "${DISTROBOX_NAME}" || true
            # Also clean up the isolated home directory
            if [[ -d "${DISTROBOX_HOME_TO_DELETE}" ]]; then
                log_info "Cleaning up isolated home directory: ${DISTROBOX_HOME_TO_DELETE}"
                rm -rf "${DISTROBOX_HOME_TO_DELETE}"
            fi
            log_success "Deleted existing distrobox"
        else
            log_info "No existing distrobox found with name: ${DISTROBOX_NAME}"
        fi
    fi
fi

# Create the distrobox
# Using --home to create an isolated home directory, preventing host dotfiles from leaking in
# This avoids conflicts with host tools like mise, rbenv, etc. that may have different paths
log_info "Creating distrobox..."

# Use custom home if specified, otherwise use default isolated home
if [[ -n "${CUSTOM_HOME}" ]]; then
    DISTROBOX_HOME="${CUSTOM_HOME}"
else
    DISTROBOX_HOME="$HOME/.distrobox-homes/${DISTROBOX_NAME}"
fi
mkdir -p "${DISTROBOX_HOME}"
log_info "Using home directory: ${DISTROBOX_HOME}"

if [[ "$ROOTFUL" == "true" ]]; then
    distrobox create --name "${DISTROBOX_NAME}" --image "${BASE_IMAGE}" \
        --root --init \
        --home "${DISTROBOX_HOME}" \
        --additional-packages "systemd libpam-systemd curl git python3 python3-pip python3-venv ca-certificates gnupg lsb-release" \
        --yes
else
    distrobox create --name "${DISTROBOX_NAME}" --image "${BASE_IMAGE}" \
        --home "${DISTROBOX_HOME}" \
        --additional-packages "curl git python3 python3-pip python3-venv" \
        --yes
fi

log_success "Distrobox '${DISTROBOX_NAME}' created"

# Before creating SETUP_SCRIPT, capture host project path
HOST_PROJECT_PATH="$(pwd)"

# Create setup script to run inside the distrobox
# Using a temp file in current directory to avoid /tmp issues
SETUP_SCRIPT="$(pwd)/.harbor_setup_$$.sh"
cat > "${SETUP_SCRIPT}" << INNER_SCRIPT
#!/usr/bin/env bash
set -euo pipefail

BOXNAME="${DISTROBOX_NAME}"
IS_ROOTFUL="${ROOTFUL}"
TARGET_USER="${DISTROBOX_USER}"
TARGET_UID="$(id -u)"
HOST_PROJECT_PATH="${HOST_PROJECT_PATH}"
DISTROBOX_HOME="${DISTROBOX_HOME}"

# Ensure the home dir exists and is owned appropriately
USER_HOME="\${DISTROBOX_HOME}"
mkdir -p "\${USER_HOME}"

# If the host project is visible under /run/host, bind it to the same absolute path
# inside the container so only the project path is exposed.
if [[ -n "${HOST_PROJECT_PATH}" && -d "/run/host${HOST_PROJECT_PATH}" ]]; then
    echo "Binding host project into container at ${HOST_PROJECT_PATH}..."
    sudo mkdir -p "$(dirname "${HOST_PROJECT_PATH}")" || true
    sudo mount --bind "/run/host${HOST_PROJECT_PATH}" "${HOST_PROJECT_PATH}" 2>/dev/null || true
fi

# Mask /run/host to prevent other host dotfiles from being visible inside the container
# This hides host-mounted home and other host files that may leak configuration
if [[ -d /run/host ]]; then
    echo "Hiding host mounts under /run/host to prevent config leakage..."
    sudo mkdir -p /run/host-block || true
    # Try bind-mounting an empty dir over /run/host; ignore failures
    sudo mount --bind /run/host-block /run/host 2>/dev/null || true
fi

# If running as root (we enter the container as root to do setup), create the non-root user
if [[ "\$EUID" -eq 0 ]]; then
    echo "=== Creating non-root user inside distrobox: \$TARGET_USER (uid: \$TARGET_UID) ==="
    if id -u "\$TARGET_USER" &>/dev/null; then
        echo "User \$TARGET_USER already exists"
    else
        # Create user with same UID to avoid ownership issues and create home at isolated path
        useradd -m -u "\$TARGET_UID" -d "\$USER_HOME" -s /bin/bash "\$TARGET_USER" || true
        echo "Created user \$TARGET_USER with home \$USER_HOME"
    fi

    # Set a default password for the user (or disable password requirement)
    # This prevents the "first time user password setup" prompt
    echo "\$TARGET_USER:\$TARGET_USER" | chpasswd || true

    # Ensure home ownership
    chown -R "\$TARGET_USER":"\$TARGET_USER" "\$USER_HOME" || true

    # Add the user to the docker group so they can use docker without sudo
    if getent group docker >/dev/null; then
        usermod -aG docker "\$TARGET_USER" || true
        echo "Added \$TARGET_USER to docker group"
    else
        echo "docker group not found yet; attempting to create and add"
        groupadd -f docker || true
        usermod -aG docker "\$TARGET_USER" || true
    fi

    # Add user to sudo group and allow passwordless sudo for this user
    usermod -aG sudo "\$TARGET_USER" || true
    echo "\$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-\$TARGET_USER-nopasswd
    chmod 440 /etc/sudoers.d/99-\$TARGET_USER-nopasswd

    # Create minimal .bashrc for the user to avoid inheriting problematic host dotfiles
    if [[ ! -f "\$USER_HOME/.bashrc" ]]; then
        cat > "\$USER_HOME/.bashrc" << 'BASHRC'
# Minimal bashrc for distrobox user
export PATH="$HOME/.local/bin:$PATH"
# Load direnv if available
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi
BASHRC
        chown "\$TARGET_USER":"\$TARGET_USER" "\$USER_HOME/.bashrc" || true
    fi

    # Ensure .profile exists and is safe
    if [[ ! -f "\$USER_HOME/.profile" ]]; then
        cat > "\$USER_HOME/.profile" << 'PROFILE'
# Minimal profile for distrobox user
if [ -n "$BASH_VERSION" ]; then
  [ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
fi
PROFILE
        chown "\$TARGET_USER":"\$TARGET_USER" "\$USER_HOME/.profile" || true
    fi

fi

# Later, after installing harbor, create a non-root wrapper so users and CI can run harbor as non-root
# (we'll append this near the harbor install verification section)

# Set up isolation for mise and/or direnv if they are being installed
# This prevents host config leakage from /run/host/
NEEDS_ISOLATION=false
MISE_ISOLATION=""
DIRENV_ISOLATION=""

if [[ "${INSTALL_MISE}" == "true" ]]; then
    NEEDS_ISOLATION=true
    MISE_ISOLATION='# mise isolation - point to distrobox-local paths BEFORE mise can read host config
export MISE_CONFIG_DIR="$HOME/.config/mise"
export MISE_DATA_DIR="$HOME/.local/share/mise"
export MISE_CACHE_DIR="$HOME/.cache/mise"
export MISE_GLOBAL_CONFIG_FILE="$HOME/.config/mise/config.toml"
export MISE_TRUSTED_CONFIG_PATHS="$HOME"
# Disable mise from reading any config outside of HOME
export MISE_IGNORED_CONFIG_PATHS="/run/host"'
fi

if [[ "${INSTALL_DIRENV}" == "true" ]]; then
    NEEDS_ISOLATION=true
    DIRENV_ISOLATION='# direnv isolation
export DIRENV_CONFIG="$HOME/.config/direnv"'
fi

if [[ "\$NEEDS_ISOLATION" == "true" ]]; then
    echo "Setting up environment isolation..."

    # Create /etc/profile.d script to set isolation environment variables very early
    sudo tee /etc/profile.d/00-distrobox-isolation.sh > /dev/null << ISOLATION_SCRIPT
# Distrobox isolation - prevent host config leakage from /run/host/
# This must run early to override any host-mounted configs

\$MISE_ISOLATION

\$DIRENV_ISOLATION

# Ensure local bin is in PATH
export PATH="\\\$HOME/.local/bin:\\\$PATH"
ISOLATION_SCRIPT
    sudo chmod +x /etc/profile.d/00-distrobox-isolation.sh

    # Create an early isolation script as well
    sudo tee /etc/profile.d/000-isolation-early.sh > /dev/null << EARLY_ISOLATION
# Very early isolation - runs before most other profile.d scripts
# Prevent mise/direnv from reading host configs mounted at /run/host/
\$MISE_ISOLATION
\$DIRENV_ISOLATION
EARLY_ISOLATION
    sudo chmod +x /etc/profile.d/000-isolation-early.sh
fi

# Remove any host mise/direnv hooks that distrobox may have linked
# These can cause the host tools to be invoked before our isolation kicks in
echo "Removing host shell integration links..."
# Check for and remove problematic host-linked shell configs
if [[ "${INSTALL_MISE}" == "true" ]]; then
    for f in /etc/profile.d/*mise*; do
        if [[ -f "\$f" ]] && grep -q "/run/host" "\$f" 2>/dev/null; then
            echo "Removing host-linked config: \$f"
            sudo rm -f "\$f"
        fi
    done
fi
if [[ "${INSTALL_DIRENV}" == "true" ]]; then
    for f in /etc/profile.d/*direnv*; do
        if [[ -f "\$f" ]] && grep -q "/run/host" "\$f" 2>/dev/null; then
            echo "Removing host-linked config: \$f"
            sudo rm -f "\$f"
        fi
    done
fi

# Clean up any host mise/direnv hooks that may have been copied to the distrobox bashrc
# Distrobox can copy parts of the host's shell config
if [[ -f "\$HOME/.bashrc" ]]; then
    echo "Cleaning up any inherited host tool hooks from bashrc..."
    # Remove any lines that reference /run/host or linuxbrew paths
    sed -i '/\/run\/host/d' "\$HOME/.bashrc" 2>/dev/null || true
    if [[ "${INSTALL_MISE}" == "true" ]]; then
        sed -i '/linuxbrew.*mise/d' "\$HOME/.bashrc" 2>/dev/null || true
        sed -i '/mise activate/d' "\$HOME/.bashrc" 2>/dev/null || true
    fi
    if [[ "${INSTALL_DIRENV}" == "true" ]]; then
        sed -i '/direnv hook/d' "\$HOME/.bashrc" 2>/dev/null || true
    fi
fi

# Also check .profile and .bash_profile
for rcfile in "\$HOME/.profile" "\$HOME/.bash_profile"; do
    if [[ -f "\$rcfile" ]]; then
        sed -i '/\/run\/host/d' "\$rcfile" 2>/dev/null || true
        if [[ "${INSTALL_MISE}" == "true" ]]; then
            sed -i '/linuxbrew.*mise/d' "\$rcfile" 2>/dev/null || true
            sed -i '/mise activate/d' "\$rcfile" 2>/dev/null || true
        fi
        if [[ "${INSTALL_DIRENV}" == "true" ]]; then
            sed -i '/direnv hook/d' "\$rcfile" 2>/dev/null || true
        fi
    fi
done

# Install Docker if rootful (required for harbor tasks)
if [[ "\${IS_ROOTFUL}" == "true" ]]; then
    echo ""
    echo "=== Installing Docker ==="
    if ! command -v docker &> /dev/null; then
        # Add Docker's official GPG key
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Add the repository to Apt sources
        echo \
          "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          \$(. /etc/os-release && echo "\$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Configure Docker to use vfs storage driver (for compatibility with distrobox)
        sudo mkdir -p /etc/docker
        echo '{"storage-driver": "vfs"}' | sudo tee /etc/docker/daemon.json

        # Start and enable Docker
        sudo systemctl enable docker
        sudo systemctl start docker

        echo "Docker installed successfully"
    else
        echo "Docker is already installed"
    fi

    # Add current user to docker group so we don't need sudo for docker commands
    if ! groups | grep -q docker; then
        echo "Adding user to docker group..."
        sudo usermod -aG docker \$USER
        echo "NOTE: You may need to log out and back in for docker group membership to take effect"
        echo "      Or run: newgrp docker"
    fi

    # Verify Docker is running
    if sudo systemctl is-active --quiet docker; then
        echo "Docker daemon is running"
        docker --version || sudo docker --version
    else
        echo "Starting Docker daemon..."
        sudo systemctl start docker
    fi
fi

# Install uv if not present
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Add uv to PATH for this session
export PATH="\$HOME/.local/bin:\$PATH"

# Also add to shell rc files if not already present
if [[ -f "\$HOME/.bashrc" ]]; then
    if ! grep -q '.local/bin' "\$HOME/.bashrc"; then
        echo 'export PATH="\$HOME/.local/bin:\$PATH"' >> "\$HOME/.bashrc"
    fi
fi

echo "uv version: \$(uv --version)"

# Install latest compatible Python using uv
# BLOCKER: Python 3.14 is not yet supported by harbor's dependency chain:
#   - harbor depends on daytona
#   - daytona depends on obstore>=0.7.0,<0.8.0
#   - obstore 0.7.x has no wheels with Python 3.14 ABI tag (cp314)
# Once obstore releases 3.14-compatible wheels, we can upgrade.
# Tracking: https://github.com/apache/arrow-rs/issues (obstore is part of arrow-rs)
echo "Installing Python 3.13 via uv..."
uv python install 3.13

# Remove conflicting harbor-cli if present (different project, same executable name)
if uv tool list 2>/dev/null | grep -q "harbor-cli"; then
    echo "Removing conflicting harbor-cli (different project)..."
    uv tool uninstall harbor-cli || true
fi

# Install harbor using uv tool (with Python 3.13)
echo "Installing harbor (Terminal Bench)..."
uv tool install --force --python 3.13 harbor

# Verify harbor is accessible
echo ""
echo "Verifying harbor installation..."
export PATH="\$HOME/.local/bin:\$PATH"
harbor --help > /dev/null && echo "harbor is working!" || echo "Warning: harbor --help failed"

# Verify installation
echo ""
echo "=== Checking installed tools ==="
which harbor 2>/dev/null && echo "harbor found at: \$(which harbor)" || echo "harbor not found in PATH"

# Show uv tools
echo ""
echo "=== Installed uv tools ==="
uv tool list

# Show installed Python versions
echo ""
echo "=== Installed Python versions ==="
uv python list --only-installed

# Install direnv if requested
if [[ "${INSTALL_DIRENV}" == "true" ]]; then
    echo ""
    echo "=== Installing direnv ==="

    # Configure direnv to use isolated directories (prevent host config leakage)
    # Set in /etc/environment for system-wide effect
    if ! grep -q 'DIRENV_CONFIG' /etc/environment 2>/dev/null; then
        echo "Setting direnv environment variables system-wide..."
        echo "DIRENV_CONFIG=\$HOME/.config/direnv" | sudo tee -a /etc/environment > /dev/null
    fi

    # Export for current session
    export DIRENV_CONFIG="\$HOME/.config/direnv"
    mkdir -p "\$HOME/.config/direnv"

    if ! command -v direnv &> /dev/null; then
        curl -sfL https://direnv.net/install.sh | bash
    fi

    # direnv installs to ~/.local/bin by default
    export PATH="\$HOME/.local/bin:\$PATH"

    # Add direnv hook to bashrc if not already present
    if [[ -f "\$HOME/.bashrc" ]]; then
        if ! grep -q 'direnv hook' "\$HOME/.bashrc"; then
            cat >> "\$HOME/.bashrc" << 'DIRENV_CONFIG'

# direnv configuration - use isolated config directory (prevent host config leakage)
export DIRENV_CONFIG="\$HOME/.config/direnv"
eval "\$(direnv hook bash)"
DIRENV_CONFIG
        fi
    fi

    echo "direnv version: \$(direnv --version)"
else
    echo "Skipping direnv installation (--no-direnv was specified)"
fi

# Install mise if requested
if [[ "${INSTALL_MISE}" == "true" ]]; then
    echo ""
    echo "=== Installing mise ==="

    # Configure mise to use isolated directories BEFORE any mise commands
    # This prevents reading host config from /run/host/
    # Set these in /etc/environment so they apply system-wide before any shell starts
    MISE_ENV_VARS="MISE_CONFIG_DIR=\$HOME/.config/mise
MISE_DATA_DIR=\$HOME/.local/share/mise
MISE_CACHE_DIR=\$HOME/.cache/mise
MISE_GLOBAL_CONFIG_FILE=\$HOME/.config/mise/config.toml
MISE_TRUSTED_CONFIG_PATHS=\$HOME"

    # Add to /etc/environment for system-wide effect (requires sudo)
    if ! grep -q 'MISE_CONFIG_DIR' /etc/environment 2>/dev/null; then
        echo "Setting mise environment variables system-wide..."
        echo "\$MISE_ENV_VARS" | sudo tee -a /etc/environment > /dev/null
    fi

    # Also export for current session
    export MISE_CONFIG_DIR="\$HOME/.config/mise"
    export MISE_DATA_DIR="\$HOME/.local/share/mise"
    export MISE_CACHE_DIR="\$HOME/.cache/mise"
    export MISE_GLOBAL_CONFIG_FILE="\$HOME/.config/mise/config.toml"
    export MISE_TRUSTED_CONFIG_PATHS="\$HOME"
    mkdir -p "\$HOME/.config/mise" "\$HOME/.local/share/mise" "\$HOME/.cache/mise"

    # Create an empty global config to prevent reading host's config
    touch "\$HOME/.config/mise/config.toml"

    if ! command -v mise &> /dev/null; then
        curl https://mise.run | sh
    fi

    # Add mise to PATH for this session
    export PATH="\$HOME/.local/bin:\$PATH"

    # Add mise activation to bashrc if not already present
    if [[ -f "\$HOME/.bashrc" ]]; then
        if ! grep -q 'mise activate' "\$HOME/.bashrc"; then
            # Set mise directories before activation to prevent host config leakage
            cat >> "\$HOME/.bashrc" << 'MISE_CONFIG'

# mise configuration - use isolated directories (prevent host config leakage)
export MISE_CONFIG_DIR="\$HOME/.config/mise"
export MISE_DATA_DIR="\$HOME/.local/share/mise"
export MISE_CACHE_DIR="\$HOME/.cache/mise"
export MISE_GLOBAL_CONFIG_FILE="\$HOME/.config/mise/config.toml"
export MISE_TRUSTED_CONFIG_PATHS="\$HOME"
eval "\$(\$HOME/.local/bin/mise activate bash)"
MISE_CONFIG
        fi
    fi

    # Activate mise for this session
    eval "\$(\$HOME/.local/bin/mise activate bash)" 2>/dev/null || true

    echo "mise version: \$(mise --version)"
else
    echo "Skipping mise installation (--no-mise was specified)"
fi

echo ""
echo "=== Setup complete ==="
echo "To enter this distrobox, run:"
echo "  distrobox enter --root \${BOXNAME}"
INNER_SCRIPT

chmod +x "${SETUP_SCRIPT}"

# Run the setup script inside the distrobox
log_info "Running setup inside distrobox..."
if [[ "$ROOTFUL" == "true" ]]; then
    distrobox enter --root "${DISTROBOX_NAME}" -- bash "${SETUP_SCRIPT}"
else
    distrobox enter "${DISTROBOX_NAME}" -- bash "${SETUP_SCRIPT}"
fi

# Cleanup
rm -f "${SETUP_SCRIPT}"

# Create a host-side helper script that runs harbor inside the distrobox as the non-root user
WRAPPER_PATH="$(pwd)/harbor-as-user"
PROJECT_DIR="$(pwd)"
cat > "${WRAPPER_PATH}" << EOF
#!/usr/bin/env bash
# Run harbor inside the distrobox as the non-root user created by this script.
# Usage: harbor-as-user <harbor-args...>
#
# This wrapper:
#   1. Enters the distrobox as root (required for rootful distrobox)
#   2. Switches to the non-root user via sudo -u (no password required)
#   3. Changes to the project directory
#   4. Runs harbor with the provided arguments

DISTROBOX_NAME="${DISTROBOX_NAME}"
DISTROBOX_USER="${DISTROBOX_USER}"
PROJECT_DIR="${PROJECT_DIR}"

# Use --no-workdir to prevent distrobox from trying to cd to /run/host/... (which we masked)
# Then use sudo -u to switch to the non-root user and run harbor
exec distrobox enter --root "\${DISTROBOX_NAME}" --no-workdir -- sudo -u "\${DISTROBOX_USER}" bash -c "cd '\${PROJECT_DIR}' && export PATH=\\"\\\$HOME/.local/bin:\\\$PATH\\" && harbor \$*" -- "\$@"
EOF
chmod +x "${WRAPPER_PATH}"

log_info "Created host helper: ${WRAPPER_PATH} (runs harbor inside distrobox as ${DISTROBOX_USER})"

log_success "Distrobox '${DISTROBOX_NAME}' is ready!"
echo ""
echo "To enter the distrobox as the non-root user (${DISTROBOX_USER}):"
echo "  distrobox enter --root ${DISTROBOX_NAME} -- su - ${DISTROBOX_USER}"
echo "  (or use the helper: $(pwd)/harbor-as-user --help)"
echo ""
echo "To enter as root (administrative):"
echo "  distrobox enter --root ${DISTROBOX_NAME}"
echo ""
echo "Once inside as the non-root user, you can run, for example:"
echo "  harbor --help"
echo "  harbor run --agent oracle --path <task-path>"
