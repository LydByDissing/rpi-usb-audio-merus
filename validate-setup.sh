#!/bin/bash
# Validation script - checks if the USB audio setup is working correctly
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

echo "=== USB Audio Device Validation ==="
echo

# Check if running on Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "❌ This script must be run on a Raspberry Pi"
    exit 1
fi

echo "1. Hardware Check:"
if grep -q "Pi Zero" /proc/cpuinfo 2>/dev/null; then
    echo "   ✅ Running on Raspberry Pi Zero (optimal)"
else
    echo "   ⚠️  Not running on Pi Zero - may require additional OTG configuration"
fi

echo
echo "2. Audio Devices:"
aplay -l

echo
echo "3. USB Gadget Services:"
echo "   USB Gadget Service:"
if systemctl is-active --quiet usb-gadget-audio.service; then
    echo "   ✅ usb-gadget-audio.service is running"
else
    echo "   ❌ usb-gadget-audio.service is NOT running"
    echo "   Status: $(systemctl is-active usb-gadget-audio.service)"
fi

echo "   Audio Routing Service:"
if systemctl is-active --quiet usb-audio-routing.service; then
    echo "   ✅ usb-audio-routing.service is running"
else
    echo "   ❌ usb-audio-routing.service is NOT running"
    echo "   Status: $(systemctl is-active usb-audio-routing.service)"
fi

echo
echo "4. Audio Routing Process:"
if pgrep alsaloop >/dev/null; then
    echo "   ✅ alsaloop is running (PID: $(pgrep alsaloop))"
    ps aux | grep alsaloop | grep -v grep | head -1 | awk '{print "   Command: " $11 " " $12 " " $13 " " $14 " " $15 " " $16 " " $17}'
else
    echo "   ❌ alsaloop is NOT running"
fi

echo
echo "5. USB Gadget Configuration:"
GADGET_DIR="/sys/kernel/config/usb_gadget/pi_audio"
if [ -d "$GADGET_DIR" ]; then
    echo "   ✅ USB gadget configured"
    UDC_CONTENT=$(cat "$GADGET_DIR/UDC" 2>/dev/null || echo "empty")
    if [ "$UDC_CONTENT" != "" ] && [ "$UDC_CONTENT" != "empty" ]; then
        echo "   ✅ USB gadget bound to UDC: $UDC_CONTENT"
    else
        echo "   ❌ USB gadget not bound to UDC"
    fi
else
    echo "   ❌ USB gadget not configured"
fi

echo
echo "6. Expected Audio Configuration:"
echo "   • UAC2_Gadget should be at card 2 (receives from host)"
echo "   • Audio output hardware should be available for routing"
echo "   • alsaloop routes: plughw:2,0 → audio hardware"

echo
echo "7. Host Connection Test:"
echo "   On your host computer, you should see:"
echo "   • 'lsusb' shows: Linux Foundation Multifunction Composite Gadget"
echo "   • Audio device named 'Pi Zero USB Audio' or similar"
echo "   • Device appears in audio settings/sound preferences"

echo
echo "8. Basic Functionality Test:"
if command -v speaker-test >/dev/null 2>&1; then
    echo "   Testing audio output for 2 seconds..."
    echo "   (You should hear test audio through connected speakers/headphones)"
    
    # Find audio output device  
    if aplay -l 2>/dev/null | grep -q "sndrpimerusamp"; then
        timeout 3 speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -c 2 -t wav -l 1 >/dev/null 2>&1 && echo "   ✅ Audio output test successful" || echo "   ❌ Audio output test failed"
    elif aplay -l 2>/dev/null | grep -q "card 1"; then
        timeout 3 speaker-test -D plughw:1,0 -c 2 -t wav -l 1 >/dev/null 2>&1 && echo "   ✅ Audio output test successful" || echo "   ❌ Audio output test failed"
    else
        echo "   ⚠️  No audio output device found for testing"
    fi
else
    echo "   ⚠️  speaker-test not available"
fi

echo
echo "=== Troubleshooting Tips ==="
if ! systemctl is-active --quiet usb-gadget-audio.service; then
    echo "• USB gadget service not running - try: sudo systemctl start usb-gadget-audio.service"
fi

if ! systemctl is-active --quiet usb-audio-routing.service; then
    echo "• Audio routing service not running - try: sudo systemctl start usb-audio-routing.service"
fi

if ! pgrep alsaloop >/dev/null; then
    echo "• Audio routing not active - try: ./start-routing.sh"
fi

echo "• Check service logs: journalctl -u usb-gadget-audio.service -u usb-audio-routing.service"
echo "• Verify USB connection uses DATA port (center micro USB on Pi Zero)"
echo "• Check host audio settings for 'Pi Zero USB Audio' device"
echo "• For issues: see docs/TROUBLESHOOTING.md"

echo
echo "=== Validation Complete ==="
