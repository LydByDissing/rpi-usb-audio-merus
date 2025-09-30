#!/bin/bash
# CamillaDSP Debug Script for USB Audio Device
# 
# This script helps debug CamillaDSP issues in the USB Audio Device setup
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

echo "=== CamillaDSP Debug Information ==="
echo "Copyright (C) 2024 - Licensed under GPL v3"
echo

# Check if CamillaDSP binary exists
echo "🔍 Checking CamillaDSP installation..."
if [ -x "/usr/local/bin/camilladsp" ]; then
    echo "✓ CamillaDSP binary found at /usr/local/bin/camilladsp"
    
    # Get version information
    VERSION_OUTPUT=$(/usr/local/bin/camilladsp --version 2>/dev/null || echo "Version check failed")
    echo "Version: $VERSION_OUTPUT"
    
    # Extract and show version for comparison
    CURRENT_VERSION=$(echo "$VERSION_OUTPUT" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    EXPECTED_VERSION="${CAMILLADSP_VERSION:-v3.0.1}"
    
    if [ "$CURRENT_VERSION" = "$EXPECTED_VERSION" ]; then
        echo "✓ Version matches expected ($EXPECTED_VERSION)"
    else
        echo "ℹ️  Version mismatch: installed=$CURRENT_VERSION, expected=$EXPECTED_VERSION"
        echo "   Run ./install.sh to update to the latest version"
    fi
else
    echo "❌ CamillaDSP binary not found or not executable"
    echo "   Run ./install.sh to download and install CamillaDSP"
fi

# Check configuration file
echo
echo "🔍 Checking configuration file..."
if [ -f "/usr/local/etc/camilladsp.yml" ]; then
    echo "✓ Configuration file found at /usr/local/etc/camilladsp.yml"
    echo "Configuration summary:"
    grep -A 5 "samplerate:\|capture:\|playback:" /usr/local/etc/camilladsp.yml || echo "  Error reading config"
else
    echo "❌ Configuration file not found"
fi

# Check service status
echo
echo "🔍 Checking CamillaDSP service status..."
if systemctl is-active --quiet camilladsp.service; then
    echo "✓ CamillaDSP service is running"
else
    echo "❌ CamillaDSP service is not running"
fi

systemctl status camilladsp.service --no-pager -l
echo

# Check for conflicting processes
echo "🔍 Checking for conflicting audio processes..."
ALSALOOP_PROCS=$(pgrep -f alsaloop 2>/dev/null || true)
if [ -n "$ALSALOOP_PROCS" ]; then
    echo "⚠️  Warning: Legacy alsaloop processes detected (PIDs: $ALSALOOP_PROCS)"
    echo "   These may conflict with CamillaDSP. Stop them with: sudo pkill -f alsaloop"
else
    echo "✓ No conflicting legacy processes found"
fi

# Check old service
if systemctl is-enabled --quiet usb-audio-routing.service 2>/dev/null; then
    echo "⚠️  Warning: Old usb-audio-routing service is still enabled"
    echo "   Disable it with: sudo systemctl disable usb-audio-routing.service"
elif systemctl list-unit-files | grep -q usb-audio-routing.service 2>/dev/null; then
    echo "ℹ️  Old usb-audio-routing service file exists but is disabled"
else
    echo "✓ No conflicting audio routing services found"
fi

# Check recent logs
echo "🔍 Recent CamillaDSP logs:"
journalctl -u camilladsp.service --no-pager -n 20

# Check USB gadget status
echo
echo "🔍 Checking USB audio gadget status..."
if systemctl is-active --quiet usb-gadget-audio.service; then
    echo "✓ USB gadget service is running"
else
    echo "❌ USB gadget service is not running"
fi

# Check audio devices
echo
echo "🔍 Available audio devices:"
aplay -l 2>/dev/null || echo "Unable to list audio devices"

echo
echo "🔍 Audio cards:"
cat /proc/asound/cards 2>/dev/null || echo "Unable to read /proc/asound/cards"

# Check ALSA configuration
echo
echo "🔍 Testing ALSA device access..."
echo "USB Gadget (plughw:2,0):"
arecord -D plughw:2,0 -t wav -f S16_LE -r 48000 -c 2 /dev/null --max-file-time 1 2>&1 | head -3

echo "Merus Amp (hw:CARD=sndrpimerusamp,DEV=0):"
speaker-test -D hw:CARD=sndrpimerusamp,DEV=0 -t sine -f 440 -s 1 -c 2 2>&1 | head -3

# Check CamillaDSP API
echo
echo "🔍 Testing CamillaDSP API..."
if command -v curl >/dev/null 2>&1; then
    echo "API Status:"
    curl -s --connect-timeout 3 http://localhost:1234/api/v1/state 2>/dev/null || echo "API not responding"
else
    echo "curl not available - install with: sudo apt install curl"
fi

echo
echo "=== Debug Complete ==="
echo
echo "Common Issues & Solutions:"
echo "• CamillaDSP not starting: Check audio device names in config"
echo "• No audio: Verify USB gadget and Merus amp are working"
echo "• Permission errors: Ensure pi user is in audio group"
echo "• Config errors: Validate YAML syntax in /usr/local/etc/camilladsp.yml"
echo "• API not responding: Check port 1234 is not blocked"
echo
echo "Configuration Management:"
echo "• Validate config: /usr/local/bin/camilladsp -c /usr/local/etc/camilladsp.yml"
echo "• Reload config: ./reload-config.sh (defaults to SIGHUP method)"
echo "• Watch for changes: ./watch-config.sh (auto-reload on file changes)"
echo "• API endpoint: http://localhost:1234 (if enabled)"
echo
echo "Manual testing:"
echo "• Test USB gadget: arecord -D plughw:2,0 -t wav test.wav"
echo "• Test Merus amp: speaker-test -D hw:CARD=sndrpimerusamp,DEV=0"
echo "• Manual CamillaDSP: sudo -u pi /usr/local/bin/camilladsp /usr/local/etc/camilladsp.yml"
