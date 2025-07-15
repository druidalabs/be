#!/bin/bash

# Fix Node.js installation issues
# Run this script if you encounter Node.js installation conflicts

set -e

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log_info "Fixing Node.js installation conflicts..."

# Method 1: Force remove conflicting packages
log_info "Method 1: Force removing conflicting packages..."
apt remove --purge -y nodejs npm libnode-dev node-gyp || true
apt autoremove -y
apt autoclean

# Clean up leftover files
log_info "Cleaning up leftover files..."
rm -rf /usr/lib/node_modules
rm -rf /usr/include/node
rm -rf /usr/share/nodejs
rm -f /usr/bin/node
rm -f /usr/bin/npm
rm -f /usr/bin/npx

# Remove NodeSource repository if it exists
rm -f /etc/apt/sources.list.d/nodesource.list
rm -f /etc/apt/trusted.gpg.d/nodesource.gpg

# Update package database
apt update

# Method 2: Install using snap (alternative)
log_info "Method 2: Installing Node.js using snap..."
if command -v snap >/dev/null 2>&1; then
    snap install node --classic
    
    # Create symlinks for compatibility
    ln -sf /snap/bin/node /usr/local/bin/node
    ln -sf /snap/bin/npm /usr/local/bin/npm
    ln -sf /snap/bin/npx /usr/local/bin/npx
    
    log_success "Node.js installed via snap"
else
    log_warn "Snap not available, trying alternative method..."
    
    # Method 3: Install from official NodeSource repository (clean)
    log_info "Method 3: Installing from NodeSource repository..."
    
    # Add NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    
    # Install with force overwrite
    apt install -y --force-overwrite nodejs
fi

# Verify installation
log_info "Verifying Node.js installation..."
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    log_success "Node.js version: $NODE_VERSION"
else
    log_error "Node.js installation failed"
    exit 1
fi

if command -v npm >/dev/null 2>&1; then
    NPM_VERSION=$(npm --version)
    log_success "npm version: $NPM_VERSION"
else
    log_error "npm installation failed"
    exit 1
fi

# Update npm to latest version
log_info "Updating npm to latest version..."
npm install -g npm@latest

log_success "Node.js installation fixed successfully!"
echo
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "Location: $(which node)"