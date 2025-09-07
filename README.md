# Samsung Galaxy Book Linux - Unified Configuration

[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04+-orange.svg)](https://ubuntu.com/)
[![Kernel](https://img.shields.io/badge/Kernel-6.14.0+-blue.svg)](https://kernel.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

This repository unifies the configurations and drivers necessary to run Linux on Samsung Galaxy Book with complete functionality. It combines the best practices from the [galaxy-book2-pro-linux](https://github.com/joshuagrisham/galaxy-book2-pro-linux) and [samsung-galaxybook-extras](https://github.com/joshuagrisham/samsung-galaxybook-extras) repositories.

## 📋 Table of Contents

- [Supported Models](#-supported-models)
- [System Requirements](#-system-requirements)
- [Quick Installation](#-quick-installation)
- [Manual Installation](#-manual-installation)
- [Features](#-features)
- [Troubleshooting](#-troubleshooting)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [License](#-license)

## 🖥️ Supported Models

### ✅ Tested and Functional
- **NP950XEE** - Galaxy Book2 Pro 360 (13.3")
- **NP950XED** - Galaxy Book2 Pro (13.3")
- **NP950XDB** - Galaxy Book2 Pro (15.6")
- **NP950XCJ** - Galaxy Book2 Pro 360 (15.6")
- **NP950QDB** - Galaxy Book2 Pro (15.6")

### ⚠️ Experimental Support
- **NP750XFH** - Galaxy Book Pro 360 (13.3")
- **NP750XGJ** - Galaxy Book Pro (13.3")
- **NP960XFH** - Galaxy Book3 Pro 360 (13.3")

## 🔧 System Requirements

### Operating System
- **Ubuntu 22.04+** (tested on 24.04)
- **Linux Kernel 6.14.0+** (recommended for complete functionality)
- **Kernel 6.2.0+** (basic functionality)

### Hardware
- Samsung Galaxy Book (models listed above)
- At least 4GB RAM
- 10GB free disk space

### BIOS/UEFI
- **Secure Boot**: Disabled OR configured for "Secure Boot Supported OS"
- **Fast Boot**: Disabled
- **Legacy Boot**: Disabled (UEFI only)

## 🚀 Quick Installation

### Method 1: Automated Script (Recommended)

```bash
# 1. Download the project
git clone https://github.com/Huttysam/samsung-galaxybook-linux-unified.git
cd samsung-galaxybook-linux-unified

# 2. Run installation script
chmod +x install.sh
./install.sh

# 3. Reboot the system
sudo reboot
```

### Method 2: Manual Installation

Follow the detailed steps in the [Manual Installation](#-manual-installation) section.

### Installation Verification

After installation, verify everything is working:

```bash
# Verify Intel GPU and drivers
./verify-gpu.sh

# Verify OpenCL devices (should show Intel GPU)
clinfo | grep "Device Name"

# Verify media drivers (should show Intel media driver)
vainfo

# Verify fingerprint reader (should show Egis device)
lsusb | grep "1c7a:0582"

# Verify audio (should show Realtek ALC298)
aplay -l | grep "ALC298"

# Verify keyboard configuration
systemd-hwdb query | grep "samsung-galaxybook"
```

## 📖 Manual Installation

### Step 1: System Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
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
    lsb-release
```

### Step 2: Keyboard Configuration

```bash
# Copy keyboard configuration
sudo cp 61-keyboard-samsung-galaxybook.hwdb /etc/udev/hwdb.d/

# Update hardware database
sudo systemd-hwdb update
sudo udevadm trigger
```

### Step 3: Audio Configuration

```bash
# Create audio configuration
sudo tee /etc/modprobe.d/audio-fix.conf > /dev/null <<EOF
# Samsung Galaxy Book Audio Configuration
options snd-hda-intel model=alc298-samsung-amp-v2-2-amps
EOF
```

### Step 4: GRUB Configuration

```bash
# Backup GRUB
sudo cp /etc/default/grub /etc/default/grub.backup

# Add kernel parameters
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&i915.enable_dpcd_backlight=3 i915.enable_dp_mst=0 i915.enable_psr2_sel_fetch=1 /' /etc/default/grub

# Update GRUB
sudo update-grub
```

### Step 5: Fingerprint Reader Configuration

```bash
# Verify device is present
lsusb | grep "1c7a:0582"

# Enroll fingerprint
fprintd-enroll
```

### Step 6: Intel GPU Driver Installation

```bash
# Verify Ubuntu version
lsb_release -a

# For Ubuntu 24.04+ (recommended)
sudo apt-get update
sudo apt-get install -y software-properties-common

# Add Intel Graphics PPA
sudo add-apt-repository -y ppa:kobuk-team/intel-graphics

# Install compute packages
sudo apt-get install -y libze-intel-gpu1 libze1 intel-metrics-discovery intel-opencl-icd clinfo intel-gsc

# Install media packages
sudo apt-get install -y intel-media-va-driver-non-free libmfx-gen1 libvpl2 libvpl-tools libva-glx2 va-driver-all vainfo

# For development (PyTorch, etc.)
sudo apt-get install -y libze-dev intel-ocloc

# For ray tracing (optional)
sudo apt-get install -y libze-intel-gpu-raytracing

# Add user to render group
sudo gpasswd -a ${USER} render
newgrp render
```

### Step 7: Battery Optimization

```bash
# Configure PowerTOP
sudo systemctl enable powertop.service

# Calibrate PowerTOP (optional)
sudo powertop --calibrate
```

## ✨ Features

### ⌨️ Keyboard
- **Function Keys**: Fn+F1 (Settings), Fn+F5 (Touchpad), Fn+F7/F8 (Volume)
- **Keyboard Backlight**: Automatic control via samsung-galaxybook driver
- **Layout**: Full support for pt-br abnt2
- **CapsLock**: Correct operation in all applications

### 🔊 Audio
- **Speakers**: Support for ALC298 with Samsung amplifiers
- **3.5mm Input**: Full functionality
- **Bluetooth**: Native support
- **USB Audio**: Works on USB-A and USB-C ports

### 🖥️ Display
- **Screen Brightness**: Functional control via `i915.enable_dpcd_backlight=3`
- **OLED**: Full support for OLED displays
- **Resolution**: Support for native resolutions

### 🔐 Fingerprint Reader
- **Device**: Egis Technology (LighTuning) Match-on-Chip (ID 1c7a:0582)
- **Driver**: libfprint with experimental support
- **Features**: Login, sudo, authentication

### ⚡ Battery
- **Duration**: 5-7 hours of normal use
- **Optimization**: PowerTOP with auto-tune
- **Charging**: Automatic stop at 85% (configurable in BIOS)

### 🔌 Thunderbolt
- **Port**: USB-C (closer to the front)
- **Dock**: Support for Thunderbolt 3/4 docks
- **Display**: DisplayPort more stable than HDMI
- **Power Delivery**: Works via dock

### 🎮 Intel GPU
- **Drivers**: Intel Graphics PPA with full support
- **OpenCL**: Support for parallel computing
- **Media**: Hardware acceleration for video
- **Ray Tracing**: Experimental support (optional)
- **Development**: PyTorch, OpenVINO, etc.

## 🔧 Troubleshooting

### Problem: CapsLock not working
**Symptom**: CapsLock produces '—' instead of toggling case

**Solution**:
```bash
# Check for custom DSDT in GRUB
grep "acpi_override" /etc/default/grub

# If found, remove (common cause of the problem)
sudo sed -i 's/ acpi_override=\/boot\/.*\.aml//' /etc/default/grub
sudo update-grub
sudo reboot
```

### Problem: Speakers not working
**Symptom**: No sound from speakers, but works with headphones

**Solution**:
```bash
# Run activation script
./sound/necessary-verbs.sh

# Or run individual speaker scripts if needed
./sound/init-back-left.sh
./sound/init-back-right.sh
./sound/init-front-left.sh
./sound/init-front-right.sh
```

### Problem: Screen brightness not controlling
**Symptom**: Brightness keys not working

**Solution**:
```bash
# Check kernel parameters
grep "i915.enable_dpcd_backlight" /etc/default/grub

# If not found, add
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&i915.enable_dpcd_backlight=3 /' /etc/default/grub
sudo update-grub
sudo reboot
```

### Problem: Intel GPU not detected
**Symptom**: `clinfo` doesn't show Intel devices or permission error

**Solution**:
```bash
# Check if user is in render group
groups $USER

# If not, add
sudo gpasswd -a ${USER} render
newgrp render

# Verify driver installation
clinfo | grep "Device Name"

# Check permissions
ls -la /dev/dri/

# If necessary, reboot system
sudo reboot
```

### Problem: Hardware acceleration not working
**Symptom**: Videos don't use hardware acceleration

**Solution**:
```bash
# Check media drivers
vainfo

# Check supported codecs
vainfo --display drm --device /dev/dri/renderD128

# Reinstall media drivers if necessary
sudo apt-get install --reinstall intel-media-va-driver-non-free
```

### Problem: Fingerprint reader not detected
**Symptom**: `lsusb` doesn't show device 1c7a:0582

**Solution**:
```bash
# Check if device is present
lsusb -v | grep -A 5 -B 5 "1c7a:0582"

# If not found, may be hardware or BIOS issue
```

### Problem: Thunderbolt dock not working
**Symptom**: Dock not recognized or display not working

**Solution**:
```bash
# Check if parameters are already present
grep "i915.enable_dp_mst\|i915.enable_psr2_sel_fetch" /etc/default/grub

# If not found, add specific dock parameters
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&i915.enable_dp_mst=0 i915.enable_psr2_sel_fetch=1 /' /etc/default/grub
sudo update-grub
sudo reboot

# Important: Connect dock BEFORE turning on the notebook
```

## 📁 Project Structure

```
samsung-galaxybook-linux-unified/
├── install.sh                          # Automated installation script
├── verify-gpu.sh                       # GPU verification script
├── README.md                           # This file (Portuguese)
├── README-PT.md                        # Portuguese version (alternative)
├── LICENSE                             # MIT License
├── 61-keyboard-samsung-galaxybook.hwdb # Keyboard configuration
├── dsdt/                               # DSDT files for different models
│   ├── NP750XFH-dsdt.dsl              # Galaxy Book Pro 360 (13.3")
│   ├── NP750XGJ-dsdt.dsl              # Galaxy Book Pro (13.3")
│   ├── NP950QDB-dsdt.dsl              # Galaxy Book2 Pro (15.6")
│   ├── NP950XCJ-dsdt.dsl              # Galaxy Book2 Pro 360 (15.6")
│   ├── NP950XDB-dsdt.dsl              # Galaxy Book2 Pro (15.6")
│   ├── NP950XED-dsdt.dsl              # Galaxy Book2 Pro (13.3")
│   └── NP960XFH-dsdt.dsl              # Galaxy Book3 Pro 360 (13.3")
├── fingerprint/                        # Fingerprint reader configurations
│   ├── egismoc-1c7a-0582.py           # Egis MOC driver (main)
│   ├── egismoc-1c7a-05a5.py           # Egis MOC driver (alternative)
│   ├── egismoc-sdcp-1c7a-0582.py      # Egis MOC SDCP driver
│   ├── libfprint.md                   # libfprint documentation
│   └── readme.md                      # Fingerprint setup guide
├── sound/                              # Audio scripts and configurations
│   ├── necessary-verbs.sh              # Main audio activation script
│   ├── init-back-left.sh              # Back left speaker init
│   ├── init-back-right.sh             # Back right speaker init
│   ├── init-front-left.sh             # Front left speaker init
│   ├── init-front-right.sh            # Front right speaker init
│   ├── init-initial-coef-values.sh    # Initial coefficient values
│   ├── back-left-on.sh                # Back left speaker on
│   ├── back-left-off.sh               # Back left speaker off
│   ├── back-right-on.sh               # Back right speaker on
│   ├── back-right-off.sh              # Back right speaker off
│   ├── front-left-on.sh               # Front left speaker on
│   ├── front-left-off.sh              # Front left speaker off
│   ├── front-right-on.sh              # Front right speaker on
│   ├── front-right-off.sh             # Front right speaker off
│   ├── RtHDDump.txt                   # Realtek HD Audio dump
│   ├── startvm-events.txt             # VM events log
│   ├── startvm.sh                     # VM startup script
│   ├── vfio-bind.sh                   # VFIO binding script
│   └── qemu/                          # QEMU development tools
│       ├── hda-verb-log-to-csv.py     # HDA verb log converter
│       ├── vfio-common.patch          # VFIO common patch
│       └── hw/                        # Hardware definitions
│           └── vfio/
│               └── common.c           # VFIO common code
└── wmi/                                # WMI configurations
    ├── DSDT.aml                       # DSDT binary file
    ├── DSDT.dsl                       # DSDT source file
    ├── SWSD.bmf                       # SWSD firmware
    ├── WFDE.bmf                       # WFDE firmware
    └── WFTE.bmf                       # WFTE firmware
```

## 🤝 Contributing

Contributions are welcome! To contribute:

1. **Fork** the repository
2. **Create** a branch for your feature (`git checkout -b feature/new-feature`)
3. **Commit** your changes (`git commit -am 'Add new feature'`)
4. **Push** to the branch (`git push origin feature/new-feature`)
5. **Open** a Pull Request

### Models for Testing
We are especially interested in testing new models:
- Galaxy Book3 Pro
- Galaxy Book4 Pro
- Other Galaxy Book series models

### Bug Reports
When reporting bugs, include:
- Exact notebook model
- Ubuntu version
- Kernel version (`uname -r`)
- Relevant logs (`dmesg`, `journalctl`)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments and Credits

### **Original Repositories**
This project unifies and expands the work of the following repositories:

- **[Joshua Grisham](https://github.com/joshuagrisham)** - Main author and maintainer
- **[galaxy-book2-pro-linux](https://github.com/joshuagrisham/galaxy-book2-pro-linux)** - Base for configurations and documentation
  - 174 ⭐ stars, 13 forks
  - Audio configurations, fingerprint reader, Thunderbolt
  - Initialization scripts and troubleshooting
- **[samsung-galaxybook-extras](https://github.com/joshuagrisham/samsung-galaxybook-extras)** - Driver and utilities
  - 227 ⭐ stars, 22 forks
  - Linux driver for Samsung Galaxy Book
  - DSDT files for different models
  - Keyboard hwdb configurations

### **Specific Contributions**
- **Audio Configurations**: `necessary-verbs.sh` scripts and ALC298 configurations
- **Fingerprint Reader**: libfprint driver for Egis Technology (1C7A:0582)
- **Thunderbolt**: Kernel parameters and troubleshooting
- **DSDT**: Custom files for different Galaxy Book models
- **Keyboard**: hwdb configurations for Samsung function keys

### **External Resources**
- **[Intel Graphics Drivers](https://www.intel.com.br/content/www/br/pt/download/747008/intel-arc-graphics-driver-ubuntu.html)** - Official GPU drivers
- **[Intel GPU Documentation](https://dgpu-docs.intel.com/driver/client/overview.html)** - Official documentation
- **Linux Community** - Continuous support and feedback
- **Ubuntu Community** - Operating system base

### **Licensing**
This project maintains the same MIT license as the original repositories and acknowledges all copyrights of the original works.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Huttysam/samsung-galaxybook-linux-unified/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Huttysam/samsung-galaxybook-linux-unified/discussions)
- **Wiki**: [Complete Documentation](https://github.com/Huttysam/samsung-galaxybook-linux-unified/wiki)

---

**⭐ If this project helped you, consider giving it a star! ⭐**
