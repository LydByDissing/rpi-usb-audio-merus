#!/bin/bash
# Manual CamillaDSP Audio Processing Script
#
# PURPOSE:
#   Starts CamillaDSP manually in foreground mode for testing and debugging.
#   Useful for testing configurations, troubleshooting issues, or running
#   CamillaDSP outside of the systemd service.
#
# USAGE:
#   ./start-routing.sh
#
# WHAT IT DOES:
#   1. Stops any existing CamillaDSP processes
#   2. Validates configuration files exist
#   3. Starts CamillaDSP in foreground with API enabled
#   4. Shows real-time output and logs
#
# USE WHEN:
#   - Testing new configurations before applying to service
#   - Debugging CamillaDSP startup issues
#   - Need to see real-time CamillaDSP output
#   - Service won't start and need manual troubleshooting
#
# NOTE:
#   Press Ctrl+C to stop. For production use, use systemd service instead:
#   sudo systemctl start camilladsp
#
# REQUIREMENTS:
#   - CamillaDSP binary installed (/usr/local/bin/camilladsp)
#   - Configuration file (./camilladsp.yml)
#   - Audio hardware available
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

echo "Starting audio processing: USB → CamillaDSP → Merus Amplifier"
echo "UAC2_Gadget (card 2) → CamillaDSP → Merus Amp"

# Kill any existing audio processes
pkill -f camilladsp 2>/dev/null && echo "Stopped existing CamillaDSP"
sleep 2

# Check if config file exists
if [ ! -f "/usr/local/etc/camilladsp.yml" ]; then
    echo "❌ CamillaDSP configuration not found at /usr/local/etc/camilladsp.yml"
    echo "Run ./install.sh to install CamillaDSP properly"
    exit 1
fi

# Check if binary exists
if [ ! -x "/usr/local/bin/camilladsp" ]; then
    echo "❌ CamillaDSP binary not found at /usr/local/bin/camilladsp"
    echo "Run ./install.sh to download and install CamillaDSP"
    exit 1
fi

echo "Starting CamillaDSP with API on port 1234..."

# Start CamillaDSP (same command as systemd service, but in foreground for testing)
/usr/local/bin/camilladsp -p 1234 /usr/local/etc/camilladsp.yml &

CAMILLADSP_PID=$!
echo "CamillaDSP started with PID: $CAMILLADSP_PID"
echo
echo "Audio Pipeline: UAC2_Gadget (plughw:2,0) → CamillaDSP → Merus Amp"
echo "CamillaDSP API: http://$(hostname -I | awk '{print $1}'):1234"
echo "To stop: pkill -f camilladsp or kill $CAMILLADSP_PID"
echo
echo "Configuration: /usr/local/etc/camilladsp.yml"
echo "Logs: sudo journalctl -u camilladsp -f (when using systemd service)"
echo
echo "Now test from your host by playing audio to 'Pi Zero USB Audio' device"
echo "Use ./debug-camilladsp.sh for troubleshooting"

# Wait for user to stop (optional - remove & from above to run in foreground)
echo "Press Ctrl+C to stop CamillaDSP"
wait
