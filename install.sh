#!/bin/bash

# Samsung Galaxy Book Linux Configuration Script
# Unifies configurations from galaxy-book2-pro-linux and samsung-galaxybook-extras repositories
# Compatible with Ubuntu 24.04+ and kernel 6.14.0+

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Run as normal user."
        exit 1
    fi
}

# Check operating system
check_system() {
    log "Checking operating system..."
    
    if ! command -v lsb_release &> /dev/null; then
        error "lsb_release not found. Install with: sudo apt install lsb-release"
        exit 1
    fi
    
    DISTRO=$(lsb_release -si)
    VERSION=$(lsb_release -sr)
    
    if [[ "$DISTRO" != "Ubuntu" ]]; then
        warning "This script was tested on Ubuntu. Your distribution: $DISTRO $VERSION"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    if [[ "$VERSION" < "22.04" ]]; then
        warning "Ubuntu version too old ($VERSION). Recommended: 22.04+"
    fi
    
    success "System: $DISTRO $VERSION"
}

# Check kernel
check_kernel() {
    log "Checking kernel version..."
    
    KERNEL_VERSION=$(uname -r)
    KERNEL_MAJOR=$(echo $KERNEL_VERSION | cut -d. -f1)
    KERNEL_MINOR=$(echo $KERNEL_VERSION | cut -d. -f2)
    
    if [[ $KERNEL_MAJOR -lt 6 ]] || [[ $KERNEL_MAJOR -eq 6 && $KERNEL_MINOR -lt 14 ]]; then
        warning "Kernel $KERNEL_VERSION detected. Recommended: 6.14.0+ for full support"
        warning "Some features may not work correctly"
    else
        success "Kernel $KERNEL_VERSION - Full support available"
    fi
}

# Detect notebook model
detect_model() {
    log "Detecting Samsung Galaxy Book model..."
    
    if [[ -f /sys/class/dmi/id/product_name ]]; then
        PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name)
        success "Model detected: $PRODUCT_NAME"
        
        # Check if it's a supported model
        case "$PRODUCT_NAME" in
            *NP950XEE*|*NP950XED*|*NP950XDB*|*NP950XCJ*|*NP950QDB*|*NP750XFH*|*NP750XGJ*|*NP960XFH*)
                success "Supported model: $PRODUCT_NAME"
                ;;
            *)
                warning "Untested model: $PRODUCT_NAME"
                warning "The script may work, but has not been specifically tested"
                ;;
        esac
    else
        warning "Could not detect notebook model"
    fi
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."
    
    sudo apt update
    sudo apt install -y \
        build-essential \
        linux-headers-$(uname -r) \
        dkms \
        git \
        curl \
        wget \
        acpica-tools \
        powertop \
        fprintd \
        libfprint-2-2 \
        libfprint-2-dev \
        libpam-fprintd \
        lsb-release \
        software-properties-common
    
    success "Dependencies installed"
}

# Configure keyboard
configure_keyboard() {
    log "Configuring Samsung Galaxy Book keyboard..."
    
    # Backup original file if it exists
    if [[ -f /etc/udev/hwdb.d/61-keyboard-samsung-galaxybook.hwdb ]]; then
        sudo cp /etc/udev/hwdb.d/61-keyboard-samsung-galaxybook.hwdb /etc/udev/hwdb.d/61-keyboard-samsung-galaxybook.hwdb.backup
        log "Backup created: /etc/udev/hwdb.d/61-keyboard-samsung-galaxybook.hwdb.backup"
    fi
    
    # Copy keyboard configuration file
    sudo cp 61-keyboard-samsung-galaxybook.hwdb /etc/udev/hwdb.d/
    
    # Update hwdb
    sudo systemd-hwdb update
    sudo udevadm trigger
    
    success "Keyboard configuration applied"
}

# Configure audio
configure_audio() {
    log "Configuring Samsung Galaxy Book audio..."
    
    # Backup original file if it exists
    if [[ -f /etc/modprobe.d/audio-fix.conf ]]; then
        sudo cp /etc/modprobe.d/audio-fix.conf /etc/modprobe.d/audio-fix.conf.backup
        log "Backup created: /etc/modprobe.d/audio-fix.conf.backup"
    fi
    
    # Create audio configuration
    sudo tee /etc/modprobe.d/audio-fix.conf > /dev/null <<EOF
# Samsung Galaxy Book Audio Configuration
# ALC298 with Samsung amplifiers
options snd-hda-intel model=alc298-samsung-amp-v2-2-amps
EOF
    
    success "Audio configuration applied"
    warning "Reboot the system to apply audio configurations"
}

# Configure GRUB
configure_grub() {
    log "Configuring kernel parameters in GRUB..."
    
    # Backup GRUB
    sudo cp /etc/default/grub /etc/default/grub.backup
    log "Backup created: /etc/default/grub.backup"
    
    # Kernel parameters for Samsung Galaxy Book
    KERNEL_PARAMS="i915.enable_dpcd_backlight=3 i915.enable_dp_mst=0 i915.enable_psr2_sel_fetch=1"
    
    # Check if parameters already exist
    if grep -q "i915.enable_dpcd_backlight" /etc/default/grub; then
        warning "i915 parameters already configured in GRUB"
    else
        # Add parameters to GRUB
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/&$KERNEL_PARAMS /" /etc/default/grub
        success "Kernel parameters added to GRUB"
    fi
    
    # Update GRUB
    sudo update-grub
    success "GRUB updated"
}

# Configure fingerprint reader
configure_fingerprint() {
    log "Configuring fingerprint reader..."
    
    # Check if device is present
    if lsusb | grep -q "1c7a:0582"; then
        success "Egis Technology fingerprint device detected"
        
        # Check if driver is available
        if command -v fprintd-enroll &> /dev/null; then
            log "To enroll your fingerprint, run:"
            echo "  fprintd-enroll"
            warning "Run the above command after installation to enroll your fingerprint"
        else
            warning "fprintd-enroll not found. Install with: sudo apt install fprintd"
        fi
    else
        warning "Fingerprint device not detected"
    fi
}

# Configure PowerTOP
configure_powertop() {
    log "Configuring PowerTOP for battery optimization..."
    
    if command -v powertop &> /dev/null; then
        # Create systemd service for PowerTOP
        sudo tee /etc/systemd/system/powertop.service > /dev/null <<EOF
[Unit]
Description=PowerTOP auto tune
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/sbin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
        
        sudo systemctl enable powertop.service
        success "PowerTOP configured for automatic battery optimization"
    else
        warning "PowerTOP not found. Install with: sudo apt install powertop"
    fi
}

# Configure audio scripts
configure_audio_scripts() {
    log "Configuring audio scripts..."
    
    # Make scripts executable
    chmod +x sound/*.sh
    
    # Create symbolic link for main script
    sudo ln -sf "$(pwd)/sound/necessary-verbs.sh" /usr/local/bin/samsung-audio-fix
    
    success "Audio scripts configured"
    log "To activate speakers, run: samsung-audio-fix"
    warning "WARNING: Use audio scripts at your own risk!"
}

# Install Intel GPU drivers
install_gpu_drivers() {
    log "Installing Intel GPU drivers..."
    
    # Check Ubuntu version
    UBUNTU_VERSION=$(lsb_release -rs)
    UBUNTU_MAJOR=$(echo $UBUNTU_VERSION | cut -d. -f1)
    
    if [[ $UBUNTU_MAJOR -lt 22 ]]; then
        warning "Ubuntu $UBUNTU_VERSION is not supported for Intel Graphics drivers"
        warning "Recommended: Ubuntu 22.04+ for full support"
        return 1
    fi
    
    # Add Intel Graphics PPA
    log "Adding Intel Graphics PPA..."
    sudo add-apt-repository -y ppa:kobuk-team/intel-graphics
    sudo apt update
    
    # Install compute packages
    log "Installing compute packages..."
    sudo apt install -y \
        libze-intel-gpu1 \
        libze1 \
        intel-metrics-discovery \
        intel-opencl-icd \
        clinfo \
        intel-gsc
    
    # Install media packages
    log "Installing media packages..."
    sudo apt install -y \
        intel-media-va-driver-non-free \
        libmfx-gen1 \
        libvpl2 \
        libvpl-tools \
        libva-glx2 \
        va-driver-all \
        vainfo
    
    # Install development packages
    log "Installing development packages..."
    sudo apt install -y \
        libze-dev \
        intel-ocloc
    
    # Install ray tracing (optional)
    log "Installing ray tracing support..."
    sudo apt install -y libze-intel-gpu-raytracing
    
    # Add user to render group
    log "Configuring GPU permissions..."
    sudo gpasswd -a ${USER} render
    
    success "Intel GPU drivers installed"
    log "Reboot the system to apply GPU configurations"
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           Samsung Galaxy Book Linux Configuration           ║"
    echo "║                    Installation Script                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_root
    check_system
    check_kernel
    detect_model
    
    echo
    log "Starting Samsung Galaxy Book configuration..."
    echo
    
    install_dependencies
    configure_keyboard
    configure_audio
    configure_grub
    configure_fingerprint
    configure_powertop
    configure_audio_scripts
    install_gpu_drivers
    
    echo
    success "Configuration completed successfully!"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Reboot the system to apply all configurations"
    echo "2. Test the features:"
    echo "   - Function keys (Fn+F1, Fn+F5, Fn+F7, Fn+F8, etc.)"
    echo "   - Screen brightness control"
    echo "   - Speakers (run: samsung-audio-fix)"
    echo "   - Fingerprint reader (run: fprintd-enroll)"
    echo "   - Intel GPU (run: clinfo | grep 'Device Name')"
    echo "   - Hardware acceleration (run: vainfo)"
    echo "3. To optimize battery, run: sudo powertop --calibrate"
    echo
    echo -e "${GREEN}Your Samsung Galaxy Book is ready for Linux! 🚀${NC}"
}

# Execute main function
main "$@"
