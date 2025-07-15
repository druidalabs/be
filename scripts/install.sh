#!/bin/bash

# Bitcoin Efectivo CLI Installation Script
# Usage: curl -sSL https://bitcoinefectivo.com/install.sh | bash

set -e

# Configuration
REPO="druidalabs/be"
BINARY_NAME="be"
INSTALL_DIR="/usr/local/bin"
TEMP_DIR=$(mktemp -d)
GITHUB_API_URL="https://api.github.com/repos/${REPO}/releases/latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}

# Set trap for cleanup
trap cleanup EXIT

# Detect OS and architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $OS in
        linux)
            OS="linux"
            ;;
        darwin)
            OS="darwin"
            ;;
        mingw*|msys*|cygwin*)
            OS="windows"
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    case $ARCH in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        arm*)
            ARCH="arm"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    log_info "Detected platform: $OS/$ARCH"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command_exists curl; then
        log_error "curl is required but not installed. Please install curl and try again."
        exit 1
    fi
    
    if ! command_exists tar; then
        log_error "tar is required but not installed. Please install tar and try again."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Get latest release info
get_latest_release() {
    log_info "Fetching latest release information..."
    
    if ! RELEASE_DATA=$(curl -s "$GITHUB_API_URL"); then
        log_error "Failed to fetch release information from GitHub API"
        exit 1
    fi
    
    # Extract version and download URL
    VERSION=$(echo "$RELEASE_DATA" | grep '"tag_name"' | head -n 1 | cut -d '"' -f 4)
    
    if [ -z "$VERSION" ]; then
        log_error "Failed to extract version from release data"
        exit 1
    fi
    
    # Construct download URL
    BINARY_SUFFIX=""
    if [ "$OS" = "windows" ]; then
        BINARY_SUFFIX=".exe"
    fi
    
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}-${OS}-${ARCH}${BINARY_SUFFIX}"
    
    log_info "Latest version: $VERSION"
    log_info "Download URL: $DOWNLOAD_URL"
}

# Download and install binary
download_and_install() {
    log_info "Downloading Bitcoin Efectivo CLI..."
    
    cd "$TEMP_DIR"
    
    # Download binary
    if ! curl -sL "$DOWNLOAD_URL" -o "$BINARY_NAME"; then
        log_error "Failed to download binary from $DOWNLOAD_URL"
        exit 1
    fi
    
    # Make executable
    chmod +x "$BINARY_NAME"
    
    # Check if we need sudo for installation
    if [ ! -w "$INSTALL_DIR" ]; then
        log_info "Installing to $INSTALL_DIR (requires sudo)..."
        sudo mv "$BINARY_NAME" "$INSTALL_DIR/"
    else
        log_info "Installing to $INSTALL_DIR..."
        mv "$BINARY_NAME" "$INSTALL_DIR/"
    fi
    
    log_success "Bitcoin Efectivo CLI installed successfully!"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    if ! command_exists "$BINARY_NAME"; then
        log_error "Installation failed: $BINARY_NAME command not found in PATH"
        exit 1
    fi
    
    # Test the binary
    if ! "$BINARY_NAME" --version >/dev/null 2>&1; then
        log_error "Installation failed: $BINARY_NAME binary is not working correctly"
        exit 1
    fi
    
    log_success "Installation verified successfully!"
}

# Show next steps
show_next_steps() {
    echo
    log_success "🎉 Bitcoin Efectivo CLI is now installed!"
    echo
    echo "Next steps:"
    echo "1. Run 'be --help' to see available commands"
    echo "2. Run 'be signup' to create your account"
    echo "3. Visit https://bitcoinefectivo.com to learn more"
    echo
    echo "For support, visit: https://github.com/${REPO}/issues"
}

# Main installation function
main() {
    echo
    log_info "Starting Bitcoin Efectivo CLI installation..."
    echo
    
    check_prerequisites
    detect_platform
    get_latest_release
    download_and_install
    verify_installation
    show_next_steps
    
    log_success "Installation completed successfully!"
}

# Run main function
main "$@"