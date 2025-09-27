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

# Create audio routing systemd service
echo "Creating audio routing systemd service..."
sudo tee /etc/systemd/system/usb-audio-routing.service > /dev/null << 'EOF'
[Unit]
Description=USB to Audio Hardware Routing
After=usb-gadget-audio.service sound.target
Requires=usb-gadget-audio.service
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=simple
ExecStartPre=/bin/sleep 10
ExecStartPre=-/usr/bin/pkill -f alsaloop
ExecStart=/usr/bin/alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000
Restart=on-failure
RestartSec=15
User=root
StandardOutput=journal
StandardError=journal

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

if sudo systemctl enable usb-audio-routing.service; then
    echo "✓ Audio routing service enabled for boot"
else
    echo "❌ Failed to enable audio routing service"
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
        
        # Start audio routing service
        echo "Starting audio routing service..."
        if sudo systemctl start usb-audio-routing.service; then
            echo "✓ Audio routing service started"
        else
            echo "⚠️  Audio routing service failed to start (will retry after reboot)"
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
systemctl status usb-audio-routing.service --no-pager -l || true

echo
echo "=== Installation Complete ==="
echo
echo "IMPORTANT:"
echo "1. Reboot your Pi: sudo reboot"
echo "2. After reboot, check services:"
echo "   • systemctl status usb-gadget-audio.service"
echo "   • systemctl status usb-audio-routing.service" 
echo "3. Use the DATA USB port (center micro USB), NOT the power port"
echo "4. Connect to host and check with: lsusb"
echo "5. Check audio devices with: aplay -l"
echo "6. Debug issues with: ./debug.sh"
echo
echo "AUDIO ROUTING:"
echo "• USB audio from host will automatically route to your audio output"
echo "• No additional configuration needed - routing starts automatically"
echo "• Test from host: play audio to 'Pi Zero USB Audio' device"
echo
echo "To uninstall, run: ./cleanup.sh"
