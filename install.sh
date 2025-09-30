#!/bin/bash
# Raspberry Pi Zero USB Audio Device Installation Script
# 
# This script configures a Raspberry Pi Zero W as a USB Audio Class 2 device
# with automatic routing to connected audio hardware.
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

set -e

echo "=== Raspberry Pi Zero USB Audio Device Setup ==="
echo "Copyright (C) 2024 - Licensed under GPL v3"
echo

# Check for command line options
FORCE_DOWNLOAD=false
for arg in "$@"; do
    case $arg in
        --force-download)
            FORCE_DOWNLOAD=true
            echo "ℹ️  Force download mode enabled - will re-download CamillaDSP even if correct version exists"
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --force-download    Force re-download of CamillaDSP binary"
            echo "  --help, -h          Show this help message"
            echo
            echo "Environment Variables:"
            echo "  CAMILLADSP_VERSION  Override CamillaDSP version (default: v3.0.1)"
            echo
            echo "Examples:"
            echo "  $0                                    # Normal installation"
            echo "  $0 --force-download                   # Force re-download"
            echo "  CAMILLADSP_VERSION=v3.0.0 $0         # Install specific version"
            exit 0
            ;;
    esac
done
echo

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "❌ This script must be run on a Raspberry Pi"
    exit 1
fi

# Check for Pi Zero (recommended)
if grep -q "Pi Zero" /proc/cpuinfo 2>/dev/null; then
    echo "✅ Detected Raspberry Pi Zero - optimal hardware"
else
    echo "⚠️  Not running on Pi Zero - ensure OTG USB support is available"
fi

# Update /boot/config.txt
echo "Configuring /boot/config.txt..."
if ! grep -q "dtoverlay=dwc2" /boot/config.txt; then
    echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
    echo "✓ Added dwc2 overlay"
else
    echo "✓ dwc2 overlay already present"
fi

# Update /etc/modules
echo "Configuring /etc/modules..."
sudo sed -i '/dwc2/d' /etc/modules 2>/dev/null || true
sudo sed -i '/g_audio/d' /etc/modules 2>/dev/null || true
sudo sed -i '/libcomposite/d' /etc/modules 2>/dev/null || true

echo "dwc2" | sudo tee -a /etc/modules
echo "libcomposite" | sudo tee -a /etc/modules
echo "✓ Updated kernel modules"

# Create USB gadget script
echo "Installing USB gadget script..."
sudo tee /usr/local/bin/usb-gadget-audio.sh > /dev/null << 'EOF'
#!/bin/bash
# USB Audio Gadget Configuration Script
# Creates a USB Audio Class 2 composite device

GADGET_DIR="/sys/kernel/config/usb_gadget/pi_audio"
VENDOR_ID="0x1d6b"
PRODUCT_ID="0x0104"
SERIAL="123456789"
MANUFACTURER="Raspberry Pi Foundation"
PRODUCT="Pi Zero USB Audio"

# Ensure configfs is mounted
mountpoint -q /sys/kernel/config || mount -t configfs none /sys/kernel/config

# Load libcomposite
modprobe libcomposite

# Remove existing gadget
if [ -d "$GADGET_DIR" ]; then
    echo "" > "$GADGET_DIR/UDC" 2>/dev/null || true
    rm -f "$GADGET_DIR/configs/c.1/uac2.usb0" 2>/dev/null || true
    rmdir "$GADGET_DIR/configs/c.1/strings/0x409" 2>/dev/null || true
    rmdir "$GADGET_DIR/configs/c.1" 2>/dev/null || true
    rmdir "$GADGET_DIR/functions/uac2.usb0" 2>/dev/null || true
    rmdir "$GADGET_DIR/strings/0x409" 2>/dev/null || true
    rmdir "$GADGET_DIR" 2>/dev/null || true
    sleep 1
fi

# Create gadget
mkdir -p "$GADGET_DIR"
cd "$GADGET_DIR"

# Device descriptor
echo "$VENDOR_ID" > idVendor
echo "$PRODUCT_ID" > idProduct
echo "0x0100" > bcdDevice
echo "0x0200" > bcdUSB
echo "0xEF" > bDeviceClass
echo "0x02" > bDeviceSubClass
echo "0x01" > bDeviceProtocol

# Device strings
mkdir -p strings/0x409
echo "$SERIAL" > strings/0x409/serialnumber
echo "$MANUFACTURER" > strings/0x409/manufacturer
echo "$PRODUCT" > strings/0x409/product

# Create UAC2 function
mkdir -p functions/uac2.usb0
cd functions/uac2.usb0
echo 3 > c_chmask  # Stereo (left + right channels)
echo 3 > p_chmask  # Stereo (left + right channels)
echo 48000 > c_srate
echo 48000 > p_srate
echo 2 > c_ssize
echo 2 > p_ssize

# Create configuration
cd "$GADGET_DIR"
mkdir -p configs/c.1/strings/0x409
echo "UAC2 Audio" > configs/c.1/strings/0x409/configuration
echo 500 > configs/c.1/MaxPower

# Link function to configuration
ln -s functions/uac2.usb0 configs/c.1/

# Bind to UDC
UDC=$(ls /sys/class/udc | head -1)
echo "$UDC" > UDC

echo "USB Audio Gadget configured successfully"
EOF

sudo chmod +x /usr/local/bin/usb-gadget-audio.sh
echo "✓ USB gadget script installed"

# Note: Audio routing now handled directly by systemd service
echo "✓ Audio routing will be handled by systemd service"

# Create USB gadget systemd service
echo "Creating USB gadget systemd service..."
sudo tee /etc/systemd/system/usb-gadget-audio.service > /dev/null << 'EOF'
[Unit]
Description=USB Audio Gadget
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/usb-gadget-audio.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Install CamillaDSP binary and configuration
echo "Installing CamillaDSP..."

# Download and install CamillaDSP binary
CAMILLADSP_VERSION="${CAMILLADSP_VERSION:-v3.0.1}"  # Can be overridden with env var
CAMILLADSP_ARCH="armv6"  # Compatible with all Pi models including Pi Zero
CAMILLADSP_URL="https://github.com/HEnquist/camilladsp/releases/download/${CAMILLADSP_VERSION}/camilladsp-linux-${CAMILLADSP_ARCH}.tar.gz"

# Check if CamillaDSP is already installed and up to date
NEEDS_DOWNLOAD=false

if [ -x "/usr/local/bin/camilladsp" ]; then
    echo "Checking existing CamillaDSP installation..."
    CURRENT_VERSION=$(/usr/local/bin/camilladsp --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    if [ "$CURRENT_VERSION" = "unknown" ]; then
        echo "⚠️  Could not determine current CamillaDSP version"
        NEEDS_DOWNLOAD=true
    else
    
    if [ "$CURRENT_VERSION" = "$CAMILLADSP_VERSION" ] && [ "$FORCE_DOWNLOAD" = "false" ]; then
        echo "✓ CamillaDSP $CURRENT_VERSION is already installed and up to date"
        NEEDS_DOWNLOAD=false
    else
        if [ "$FORCE_DOWNLOAD" = "true" ]; then
            echo "ℹ️  Force download requested - will re-download CamillaDSP $CAMILLADSP_VERSION"
        else
            echo "ℹ️  CamillaDSP version mismatch: installed=$CURRENT_VERSION, wanted=$CAMILLADSP_VERSION"
        fi
        NEEDS_DOWNLOAD=true
    fi
fi
else
    echo "CamillaDSP binary not found at /usr/local/bin/camilladsp"
    NEEDS_DOWNLOAD=true
fi

if [ "$NEEDS_DOWNLOAD" = "true" ]; then
    echo "Downloading CamillaDSP ${CAMILLADSP_VERSION} for ${CAMILLADSP_ARCH}..."
if command -v wget >/dev/null 2>&1; then
    wget -q --show-progress "$CAMILLADSP_URL" -O /tmp/camilladsp.tar.gz
elif command -v curl >/dev/null 2>&1; then
    curl -L "$CAMILLADSP_URL" -o /tmp/camilladsp.tar.gz
else
    echo "❌ Neither wget nor curl found. Please install one of them:"
    echo "   sudo apt update && sudo apt install wget"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "✓ CamillaDSP downloaded successfully"
    
    # Basic file size check (armv6 release should be around 2.4MB)
    FILE_SIZE=$(stat -f%z /tmp/camilladsp.tar.gz 2>/dev/null || stat -c%s /tmp/camilladsp.tar.gz 2>/dev/null)
    if [ "$FILE_SIZE" -lt 1000000 ]; then
        echo "⚠️  Warning: Downloaded file seems too small (${FILE_SIZE} bytes)"
        echo "   This might indicate a download error"
    else
        echo "✓ File size looks reasonable (${FILE_SIZE} bytes)"
    fi
else
    echo "❌ Failed to download CamillaDSP"
    exit 1
fi

# Extract and install binary
echo "Extracting CamillaDSP binary..."
cd /tmp
tar -xzf camilladsp.tar.gz
if [ -f "camilladsp" ]; then
    sudo mv camilladsp /usr/local/bin/
    sudo chmod +x /usr/local/bin/camilladsp
    sudo chown root:root /usr/local/bin/camilladsp
    echo "✓ CamillaDSP binary installed to /usr/local/bin/camilladsp"
    
    # Verify installation
    /usr/local/bin/camilladsp --version
else
    echo "❌ CamillaDSP binary not found in downloaded archive"
    exit 1
fi

# Cleanup
rm -f /tmp/camilladsp.tar.gz
cd - >/dev/null

else
    echo "✓ Skipping CamillaDSP download - already have correct version"
fi

# Create working config from template if needed
if [ ! -f "camilladsp.yml" ]; then
    if [ -f "camilladsp.yml.template" ]; then
        echo "Creating working configuration from template..."
        cp camilladsp.yml.template camilladsp.yml
        echo "✓ Created camilladsp.yml from template"
        echo "  Edit this file to customize your audio processing"
    else
        echo "❌ Neither camilladsp.yml nor camilladsp.yml.template found"
        echo "  Template file missing from $(pwd)"
        exit 1
    fi
else
    echo "✓ Found existing camilladsp.yml configuration"
fi

# Install configuration to system location
sudo mkdir -p /usr/local/etc
sudo cp camilladsp.yml /usr/local/etc/
echo "✓ CamillaDSP configuration installed to /usr/local/etc/"
echo "  Local working copy: ./camilladsp.yml"
echo "  System location: /usr/local/etc/camilladsp.yml"

# Stop and disable any old audio routing services
echo "Stopping old audio routing services..."
sudo systemctl stop usb-audio-routing.service 2>/dev/null || true
sudo systemctl disable usb-audio-routing.service 2>/dev/null || true

# Clean up any old alsaloop processes (legacy cleanup)
echo "Cleaning up any legacy alsaloop processes..."
sudo pkill -f alsaloop 2>/dev/null || true
sleep 1

# Remove old service file if it exists
sudo rm -f /etc/systemd/system/usb-audio-routing.service 2>/dev/null || true

# Create log directory for CamillaDSP
sudo mkdir -p /var/log/camilladsp
sudo chown pi:pi /var/log/camilladsp

# Create CamillaDSP systemd service
echo "Creating CamillaDSP systemd service..."
sudo tee /etc/systemd/system/camilladsp.service > /dev/null << 'EOF'
[Unit]
Description=CamillaDSP Audio Processor for USB Audio Device
Documentation=https://github.com/HEnquist/camilladsp
After=network.target sound.target usb-gadget-audio.service
Wants=sound.target
Requires=usb-gadget-audio.service

[Service]
Type=simple
User=pi
Group=audio
ExecStartPre=/bin/sleep 5
ExecStart=/usr/local/bin/camilladsp -p 1234 /usr/local/etc/camilladsp.yml
WorkingDirectory=/usr/local/etc
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment for ALSA access
Environment="HOME=/home/pi"
Environment="XDG_RUNTIME_DIR=/run/user/1000"
Environment="ALSA_CONF_PATH=/usr/share/alsa/alsa.conf"

# Security settings (relaxed for Pi compatibility and ALSA access)
NoNewPrivileges=yes
ProtectSystem=no
ProtectHome=no
PrivateTmp=no
PrivateDevices=no

# Resource limits optimized for Pi Zero
MemoryMax=64M
CPUQuota=50%

# Audio device access
SupplementaryGroups=audio

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

# Enable the services
echo "Enabling services..."
if sudo systemctl enable usb-gadget-audio.service; then
    echo "✓ USB gadget service enabled for boot"
else
    echo "❌ Failed to enable USB gadget service"
    exit 1
fi

if sudo systemctl enable camilladsp.service; then
    echo "✓ CamillaDSP service enabled for boot"
else
    echo "❌ Failed to enable CamillaDSP service"
    exit 1
fi

# Start the services now (if modules are available)
echo "Starting USB gadget service..."
if sudo systemctl start usb-gadget-audio.service; then
    echo "✓ USB gadget service started successfully"
    
    # Check if it's actually running
    sleep 2
    if systemctl is-active --quiet usb-gadget-audio.service; then
        echo "✓ USB gadget service is running"
        
        # Start CamillaDSP service
        echo "Starting CamillaDSP service..."
        if sudo systemctl start camilladsp.service; then
            echo "✓ CamillaDSP service started"
        else
            echo "⚠️  CamillaDSP service failed to start (will retry after reboot)"
        fi
    else
        echo "⚠️  USB gadget service enabled but not running (may need reboot for dwc2 overlay)"
    fi
else
    echo "⚠️  USB gadget service failed to start (likely need reboot for dwc2 overlay)"
    echo "   This is normal on first install - will work after reboot"
fi

# Show service status
echo
echo "Service status:"
systemctl status usb-gadget-audio.service --no-pager -l || true
echo
systemctl status camilladsp.service --no-pager -l || true

echo
echo "=== Installation Complete ==="
echo
echo "IMPORTANT:"
echo "1. Reboot your Pi: sudo reboot"
echo "2. After reboot, check services:"
echo "   • systemctl status usb-gadget-audio.service"
echo "   • systemctl status camilladsp.service" 
echo "3. Use the DATA USB port (center micro USB), NOT the power port"
echo "4. Connect to host and check with: lsusb"
echo "5. Check audio devices with: aplay -l"
echo "6. Debug issues with: ./debug-camilladsp.sh or ./verify-routing.sh"
echo
echo "AUDIO PROCESSING:"
echo "• USB audio from host routes through CamillaDSP to your audio output"
echo "• CamillaDSP automatically downloaded and installed (latest stable version)"
echo "• CamillaDSP provides professional audio processing (EQ, crossover, room correction, etc.)"
echo "• Web-based configuration: http://[pi-ip]:1234 (when connected to network)"
echo "• Configuration file: /usr/local/etc/camilladsp.yml (edit for custom processing)"
echo "• Live config reload: ./reload-config.sh (no service restart needed)"
echo "• Development helper: ./watch-config.sh (auto-reload on file changes)"
echo "• Professional audio pipeline with 32-bit internal processing"
echo "• Example configuration included - customize for your needs"
echo "• Test from host: play audio to 'Pi Zero USB Audio' device"
echo
echo "To uninstall, run: ./cleanup.sh"
echo "To customize audio processing, edit: /usr/local/etc/camilladsp.yml"
echo "For help with configuration: https://github.com/HEnquist/camilladsp"
