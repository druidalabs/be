#!/bin/bash

# Local build script for Bitcoin Efectivo CLI
# This script builds the CLI locally for testing

set -e

# Configuration
BINARY_NAME="be"
INSTALL_DIR="/usr/local/bin"

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Go is installed
if ! command -v go >/dev/null 2>&1; then
    log_error "Go is not installed. Please install Go first:"
    echo "  macOS: brew install go"
    echo "  Linux: sudo apt install golang-go"
    echo "  Or download from: https://golang.org/dl/"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info "Building Bitcoin Efectivo CLI..."
cd "$PROJECT_DIR"

# Build the binary
go build -ldflags="-s -w -X 'github.com/druidalabs/be/cmd.version=dev'" -o "$BINARY_NAME" .

if [ ! -f "$BINARY_NAME" ]; then
    log_error "Build failed"
    exit 1
fi

log_success "Build successful"

# Test the binary
log_info "Testing binary..."
if ./"$BINARY_NAME" --version; then
    log_success "Binary test passed"
else
    log_error "Binary test failed"
    exit 1
fi

# Install the binary
log_info "Installing to $INSTALL_DIR..."
if [ -w "$INSTALL_DIR" ]; then
    mv "$BINARY_NAME" "$INSTALL_DIR/"
    log_success "Installed successfully"
else
    log_info "Need elevated privileges to install to $INSTALL_DIR"
    if command -v sudo >/dev/null 2>&1; then
        sudo mv "$BINARY_NAME" "$INSTALL_DIR/"
        log_success "Installed successfully with sudo"
    else
        log_error "Cannot install to $INSTALL_DIR without sudo"
        log_info "You can manually copy the binary:"
        log_info "  sudo cp $BINARY_NAME $INSTALL_DIR/"
        exit 1
    fi
fi

# Verify installation
log_info "Verifying installation..."
if command -v "$BINARY_NAME" >/dev/null 2>&1; then
    log_success "Installation verified"
    echo
    echo "Bitcoin Efectivo CLI is now installed!"
    echo "Run 'be --help' to get started"
else
    log_error "Installation verification failed"
    exit 1
fi