#!/bin/bash
# Stop alsaloop processes script
# 
# This script stops any running alsaloop processes that might conflict with CamillaDSP
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

echo "=== Stop alsaloop Processes ==="
echo

# Check for running alsaloop processes
ALSALOOP_PROCS=$(pgrep -f alsaloop 2>/dev/null || true)

if [ -n "$ALSALOOP_PROCS" ]; then
    echo "Found running alsaloop processes (PIDs: $ALSALOOP_PROCS)"
    echo "Stopping alsaloop processes..."
    
    # First try gentle termination
    pkill -TERM -f alsaloop
    sleep 2
    
    # Check if any are still running
    REMAINING_PROCS=$(pgrep -f alsaloop 2>/dev/null || true)
    if [ -n "$REMAINING_PROCS" ]; then
        echo "Some processes still running, forcing termination..."
        pkill -KILL -f alsaloop
        sleep 1
    fi
    
    # Final check
    FINAL_CHECK=$(pgrep -f alsaloop 2>/dev/null || true)
    if [ -z "$FINAL_CHECK" ]; then
        echo "✓ All alsaloop processes stopped successfully"
    else
        echo "❌ Some alsaloop processes may still be running (PIDs: $FINAL_CHECK)"
        echo "   You may need to reboot to fully clear them"
    fi
else
    echo "✓ No alsaloop processes found running"
fi

# Also stop the old service if it exists and is running
if systemctl is-active --quiet usb-audio-routing.service 2>/dev/null; then
    echo
    echo "Stopping old usb-audio-routing service..."
    sudo systemctl stop usb-audio-routing.service
    echo "✓ Old service stopped"
fi

echo
echo "Now you can start CamillaDSP:"
echo "• Manually: ./start-routing.sh"
echo "• Via service: sudo systemctl start camilladsp"
echo "• Check status: sudo systemctl status camilladsp"
