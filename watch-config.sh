#!/bin/bash
# CamillaDSP Configuration File Watcher
# 
# Automatically reloads CamillaDSP when configuration file changes
# Uses inotify to monitor file changes
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

CONFIG_FILE="/usr/local/etc/camilladsp.yml"
RELOAD_SCRIPT="$(dirname "$0")/reload-config.sh"

echo "=== CamillaDSP Configuration File Watcher ==="
echo "Copyright (C) 2024 - Licensed under GPL v3"
echo

# Check if inotify-tools is available
if ! command -v inotifywait >/dev/null 2>&1; then
    echo "❌ inotify-tools not found"
    echo "   Install with: sudo apt install inotify-tools"
    echo "   Or use manual reload: ./reload-config.sh"
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Check if reload script exists
if [ ! -x "$RELOAD_SCRIPT" ]; then
    echo "❌ Reload script not found or not executable: $RELOAD_SCRIPT"
    exit 1
fi

echo "📁 Watching: $CONFIG_FILE"
echo "🔄 Reload script: $RELOAD_SCRIPT"
echo "⚠️  Press Ctrl+C to stop watching"
echo

# Main watch loop
echo "👀 Starting file watcher..."
while true; do
    # Wait for file modification
    inotifywait -e modify,moved_to,create "$CONFIG_FILE" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo
        echo "📝 Configuration file changed: $(date)"
        echo "🔄 Attempting automatic reload..."
        
        # Use SIGHUP method for fastest reload
        "$RELOAD_SCRIPT" --sighup
        RESULT=$?
        
        if [ $RESULT -eq 0 ]; then
            echo "✓ Automatic reload successful"
        else
            echo "❌ Automatic reload failed"
            echo "   Check the configuration for errors"
        fi
        
        echo
        echo "👀 Continuing to watch for changes..."
    else
        echo "⚠️  inotifywait error - restarting watcher..."
        sleep 1
    fi
done
