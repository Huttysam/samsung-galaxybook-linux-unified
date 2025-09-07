±#!/bin/bash

# Intel GPU verification script for Samsung Galaxy Book
# Verifies if GPU drivers are installed and working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if clinfo is installed
check_clinfo() {
    log "Checking clinfo installation..."
    
    if command -v clinfo &> /dev/null; then
        success "clinfo is installed"
        return 0
    else
        error "clinfo is not installed"
        warning "Install with: sudo apt install clinfo"
        return 1
    fi
}

# Check OpenCL devices
check_opencl_devices() {
    log "Checking OpenCL devices..."
    
    if command -v clinfo &> /dev/null; then
        echo "OpenCL devices found:"
        clinfo | grep -A 5 "Device Name" || warning "No OpenCL devices found"
        
        # Check specifically for Intel devices
        if clinfo | grep -q "Intel"; then
            success "Intel OpenCL devices detected"
        else
            warning "No Intel OpenCL devices detected"
        fi
    else
        error "clinfo is not available"
    fi
}

# Check render permissions
check_render_permissions() {
    log "Checking render permissions..."
    
    if groups $USER | grep -q "render"; then
        success "User is in render group"
    else
        warning "User is not in render group"
        echo "Run: sudo gpasswd -a ${USER} render"
        echo "Then: newgrp render"
    fi
    
    # Check DRI devices
    if [[ -d /dev/dri ]]; then
        echo "Available DRI devices:"
        ls -la /dev/dri/
    else
        error "Directory /dev/dri not found"
    fi
}

# Check media drivers
check_media_drivers() {
    log "Checking media drivers..."
    
    if command -v vainfo &> /dev/null; then
        echo "Available media drivers:"
        vainfo || warning "vainfo could not get information"
        
        # Check specifically for Intel drivers
        if vainfo 2>/dev/null | grep -q "Intel"; then
            success "Intel media drivers detected"
        else
            warning "Intel media drivers not detected"
        fi
    else
        error "vainfo is not installed"
        warning "Install with: sudo apt install vainfo"
    fi
}

# Check installed packages
check_installed_packages() {
    log "Checking installed GPU packages..."
    
    PACKAGES=(
        "libze-intel-gpu1"
        "libze1"
        "intel-opencl-icd"
        "intel-media-va-driver-non-free"
        "libva-glx2"
        "vainfo"
    )
    
    for package in "${PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            success "$package is installed"
        else
            warning "$package is not installed"
        fi
    done
}

# Check Intel Graphics PPA
check_intel_ppa() {
    log "Checking Intel Graphics PPA..."
    
    if grep -q "kobuk-team/intel-graphics" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        success "Intel Graphics PPA is configured"
    else
        warning "Intel Graphics PPA is not configured"
        echo "Run: sudo add-apt-repository -y ppa:kobuk-team/intel-graphics"
    fi
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Intel GPU Verification                         ║"
    echo "║                Samsung Galaxy Book                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_clinfo
    echo
    
    check_opencl_devices
    echo
    
    check_render_permissions
    echo
    
    check_media_drivers
    echo
    
    check_installed_packages
    echo
    
    check_intel_ppa
    echo
    
    echo -e "${GREEN}Verification completed!${NC}"
    echo
    echo -e "${YELLOW}Useful commands:${NC}"
    echo "- View OpenCL devices: clinfo"
    echo "- View media drivers: vainfo"
    echo "- View user groups: groups \$USER"
    echo "- View DRI devices: ls -la /dev/dri/"
}

# Execute main function
main "$@"
