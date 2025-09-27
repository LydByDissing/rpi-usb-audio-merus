#!/bin/bash
# Cleanup script - removes all USB audio gadget configuration
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

echo "=== USB Audio Gadget Cleanup ==="

# Stop and disable services
echo "Stopping audio routing service..."
if systemctl is-active --quiet usb-audio-routing.service; then
    sudo systemctl stop usb-audio-routing.service
    echo "✓ Audio routing service stopped"
else
    echo "✓ Audio routing service was not running"
fi

if systemctl is-enabled --quiet usb-audio-routing.service 2>/dev/null; then
    sudo systemctl disable usb-audio-routing.service
    echo "✓ Audio routing service disabled"
else
    echo "✓ Audio routing service was not enabled"
fi

echo "Stopping USB gadget service..."
if systemctl is-active --quiet usb-gadget-audio.service; then
    sudo systemctl stop usb-gadget-audio.service
    echo "✓ USB gadget service stopped"
else
    echo "✓ USB gadget service was not running"
fi

if systemctl is-enabled --quiet usb-gadget-audio.service 2>/dev/null; then
    sudo systemctl disable usb-gadget-audio.service
    echo "✓ USB gadget service disabled"
else
    echo "✓ USB gadget service was not enabled"
fi

# Remove service files
echo "Removing service files..."
sudo rm -f /etc/systemd/system/usb-gadget-audio.service
sudo rm -f /etc/systemd/system/usb-audio-routing.service
sudo systemctl daemon-reload

# Remove scripts
echo "Removing system scripts..."
sudo rm -f /usr/local/bin/usb-gadget-audio.sh
sudo rm -f /usr/local/bin/usb-audio-routing.sh 2>/dev/null || true

# Kill any running alsaloop processes
echo "Stopping any running audio routing..."
sudo pkill alsaloop 2>/dev/null || true

# Clean up USB gadget configuration
echo "Cleaning USB gadget configuration..."
GADGET_DIR="/sys/kernel/config/usb_gadget/pi_audio"
if [ -d "$GADGET_DIR" ]; then
    sudo bash -c "echo '' > '$GADGET_DIR/UDC'" 2>/dev/null || true
    sudo rm -f "$GADGET_DIR/configs/c.1/uac2.usb0" 2>/dev/null || true
    sudo rmdir "$GADGET_DIR/configs/c.1/strings/0x409" 2>/dev/null || true
    sudo rmdir "$GADGET_DIR/configs/c.1" 2>/dev/null || true
    sudo rmdir "$GADGET_DIR/functions/uac2.usb0" 2>/dev/null || true
    sudo rmdir "$GADGET_DIR/strings/0x409" 2>/dev/null || true
    sudo rmdir "$GADGET_DIR" 2>/dev/null || true
fi

# Clean up /etc/modules
echo "Cleaning /etc/modules..."
sudo sed -i '/dwc2/d' /etc/modules 2>/dev/null || true
sudo sed -i '/libcomposite/d' /etc/modules 2>/dev/null || true
sudo sed -i '/g_audio/d' /etc/modules 2>/dev/null || true

# Clean up /boot/config.txt
echo "Cleaning /boot/config.txt..."
sudo sed -i '/dtoverlay=dwc2/d' /boot/config.txt 2>/dev/null || true

# Unload modules
echo "Unloading USB gadget modules..."
sudo modprobe -r g_audio 2>/dev/null || true
sudo modprobe -r libcomposite 2>/dev/null || true

echo
echo "✓ Cleanup complete!"
echo "Reboot recommended: sudo reboot"
