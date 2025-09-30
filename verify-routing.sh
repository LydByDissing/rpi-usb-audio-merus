#!/bin/bash
# CamillaDSP Audio Routing Verification Script
#
# PURPOSE:
#   Comprehensive verification that audio is properly routing through CamillaDSP
#   and that configuration changes are actually being applied. Diagnoses routing
#   issues and verifies the complete audio pipeline.
#
# USAGE:
#   ./verify-routing.sh
#
# WHAT IT VERIFIES:
#   1. CamillaDSP service status and process health
#   2. Configuration file synchronization (local vs system)
#   3. Active configuration via CamillaDSP API
#   4. Audio device routing (USB gadget → CamillaDSP → output)
#   5. Filter configuration and settings
#   6. Conflicting processes that might bypass CamillaDSP
#   7. Recent logs and error conditions
#
# OUTPUT:
#   Step-by-step verification with:
#   - ✓ Success indicators for working components
#   - ❌ Error indicators for issues requiring attention
#   - ⚠️  Warnings for potential problems
#   - Detailed troubleshooting recommendations
#   - Summary with actionable next steps
#
# USE WHEN:
#   - Audio filters/processing not working as expected
#   - Configuration changes don't seem to take effect
#   - Need to verify complete audio routing pipeline
#   - Troubleshooting why audio processing isn't working
#   - After making configuration changes to verify they're active
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

echo "=== CamillaDSP Audio Routing Verification ==="
echo "Copyright (C) 2024 - Licensed under GPL v3"
echo

CONFIG_FILE="/usr/local/etc/camilladsp.yml"
LOCAL_CONFIG_FILE="./camilladsp.yml"

# Step 1: Check if CamillaDSP service is running
echo "🔍 Step 1: Checking CamillaDSP service status..."
if systemctl is-active --quiet camilladsp.service; then
    echo "✓ CamillaDSP service is running"
    
    # Get detailed service status
    echo "Service details:"
    systemctl status camilladsp.service --no-pager -l | head -10
else
    echo "❌ CamillaDSP service is NOT running!"
    echo "   This explains why the filter isn't working."
    echo "   Start it with: sudo systemctl start camilladsp"
    echo
fi

echo

# Step 2: Check which config file is being used
echo "🔍 Step 2: Checking config file locations and content..."

if [ -f "$CONFIG_FILE" ]; then
    echo "✓ System config exists: $CONFIG_FILE"
    echo "System config filter settings:"
    grep -A 5 "bass_shelf_120hz:" "$CONFIG_FILE" || echo "  No bass_shelf_120hz filter found"
else
    echo "❌ System config missing: $CONFIG_FILE"
fi

echo

if [ -f "$LOCAL_CONFIG_FILE" ]; then
    echo "✓ Local config exists: $LOCAL_CONFIG_FILE"
    echo "Local config filter settings:"
    grep -A 5 "bass_shelf_120hz:" "$LOCAL_CONFIG_FILE" || echo "  No bass_shelf_120hz filter found"
else
    echo "❌ Local config missing: $LOCAL_CONFIG_FILE"
fi

echo

# Step 3: Compare config files if both exist
if [ -f "$CONFIG_FILE" ] && [ -f "$LOCAL_CONFIG_FILE" ]; then
    echo "🔍 Step 3: Comparing config files..."
    if diff "$CONFIG_FILE" "$LOCAL_CONFIG_FILE" >/dev/null 2>&1; then
        echo "✓ Config files are identical"
    else
        echo "⚠️  Config files are DIFFERENT!"
        echo "   System config may not match your local changes"
        echo "   Differences:"
        diff "$CONFIG_FILE" "$LOCAL_CONFIG_FILE" | head -10
    fi
else
    echo "⚠️  Cannot compare - one or both config files missing"
fi

echo

# Step 4: Check CamillaDSP process details
echo "🔍 Step 4: Checking CamillaDSP process..."
CAMILLA_PID=$(pgrep -f "/usr/local/bin/camilladsp")

if [ -n "$CAMILLA_PID" ]; then
    echo "✓ CamillaDSP process running (PID: $CAMILLA_PID)"
    
    # Get process details
    echo "Process command line:"
    ps -p "$CAMILLA_PID" -o pid,ppid,cmd --no-headers | sed 's/^/  /'
    
    # Check which config file it's using
    PROCESS_CMD=$(ps -p "$CAMILLA_PID" -o cmd --no-headers)
    echo "Config file in use: $(echo "$PROCESS_CMD" | grep -o '/[^ ]*\.yml')"
else
    echo "❌ No CamillaDSP process found!"
    echo "   Service might be failed or not started"
fi

echo

# Step 5: Check audio routing
echo "🔍 Step 5: Checking audio device routing..."

echo "ALSA playback devices:"
aplay -l 2>/dev/null | grep -E "(card|device)" | head -5

echo
echo "USB Audio Gadget status:"
if aplay -l 2>/dev/null | grep -q "UAC2"; then
    echo "✓ USB Audio Gadget detected"
else
    echo "⚠️  USB Audio Gadget not found in ALSA devices"
fi

echo
echo "Merus amplifier status:"
if aplay -l 2>/dev/null | grep -q "sndrpimerusamp"; then
    echo "✓ Merus amplifier detected"
else
    echo "⚠️  Merus amplifier not found in ALSA devices"
fi

echo

# Step 6: Check CamillaDSP API if available
echo "🔍 Step 6: Testing CamillaDSP API..."
if command -v curl >/dev/null 2>&1; then
    API_RESPONSE=$(curl -s --connect-timeout 3 http://localhost:1234/api/v1/state 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$API_RESPONSE" ]; then
        echo "✓ CamillaDSP API is responding"
        echo "API State: $API_RESPONSE"
    else
        echo "❌ CamillaDSP API not responding on port 1234"
        echo "   This suggests CamillaDSP is not running with API enabled"
    fi
else
    echo "⚠️  curl not available - cannot test API"
fi

echo

# Step 7: Recent logs
echo "🔍 Step 7: Recent CamillaDSP logs..."
echo "Last 10 log entries:"
journalctl -u camilladsp.service --no-pager -n 10 --since "10 minutes ago" | sed 's/^/  /'

echo

# Step 8: Audio process conflicts
echo "🔍 Step 8: Checking for conflicting audio processes..."
ALSALOOP_PROCS=$(pgrep -f alsaloop 2>/dev/null || true)
if [ -n "$ALSALOOP_PROCS" ]; then
    echo "⚠️  alsaloop processes still running (PIDs: $ALSALOOP_PROCS)"
    echo "   These may bypass CamillaDSP! Stop them with: sudo pkill -f alsaloop"
else
    echo "✓ No conflicting alsaloop processes"
fi

echo

# Summary and recommendations
echo "🎯 SUMMARY AND RECOMMENDATIONS:"
echo

if systemctl is-active --quiet camilladsp.service && [ -n "$CAMILLA_PID" ]; then
    echo "✅ CamillaDSP appears to be running correctly"
    
    if [ -f "$CONFIG_FILE" ] && [ -f "$LOCAL_CONFIG_FILE" ]; then
        if ! diff "$CONFIG_FILE" "$LOCAL_CONFIG_FILE" >/dev/null 2>&1; then
            echo "⚠️  ISSUE: Config files don't match"
            echo "   → Copy local config to system: sudo cp $LOCAL_CONFIG_FILE $CONFIG_FILE"
            echo "   → Then reload: ./reload-config.sh"
        else
            echo "✅ Config files are synchronized"
            echo "   If you're not hearing the -24dB filter, check:"
            echo "   1. Audio is playing through 'Pi Zero USB Audio' device"
            echo "   2. Volume levels aren't masking the effect"
            echo "   3. Test with audio content that has frequencies around 1000Hz"
        fi
    else
        echo "❌ ISSUE: Missing config files"
        echo "   → Run ./install.sh to set up configuration properly"
    fi
else
    echo "❌ MAJOR ISSUE: CamillaDSP is not running!"
    echo "   → Start service: sudo systemctl start camilladsp"
    echo "   → Check status: sudo systemctl status camilladsp"
    echo "   → View logs: sudo journalctl -u camilladsp -f"
    echo "   → If still failing, run: ./install.sh to reinstall"
fi

if [ -n "$ALSALOOP_PROCS" ]; then
    echo "❌ ROUTING ISSUE: alsaloop is bypassing CamillaDSP!"
    echo "   → Stop alsaloop: sudo pkill -f alsaloop"
    echo "   → Disable old service: sudo systemctl disable usb-audio-routing"
fi
