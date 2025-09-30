#!/bin/bash
# CamillaDSP Configuration Reload Script
# 
# This script provides multiple methods to reload CamillaDSP configuration
# Based on: https://github.com/HEnquist/camilladsp?tab=readme-ov-file#reloading-the-configuration
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

echo "=== CamillaDSP Configuration Reload ==="
echo "Copyright (C) 2024 - Licensed under GPL v3"
echo

CONFIG_FILE="/usr/local/etc/camilladsp.yml"
SERVICE_NAME="camilladsp.service"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Check if CamillaDSP service is running
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "❌ CamillaDSP service is not running"
    echo "   Start it with: sudo systemctl start $SERVICE_NAME"
    exit 1
fi

echo "🔍 Current CamillaDSP status:"
systemctl status "$SERVICE_NAME" --no-pager -l | head -5

echo
echo "Available reload methods:"
echo "1. SIGHUP signal (recommended)"
echo "2. Systemd service restart"
echo "3. Websocket API (if available)"
echo

# Method 1: SIGHUP signal (most efficient)
reload_with_sighup() {
    echo "🔄 Reloading configuration using SIGHUP signal..."
    
    # Get the PID of the CamillaDSP process
    CAMILLADSP_PID=$(pgrep -f "/usr/local/bin/camilladsp")
    
    if [ -z "$CAMILLADSP_PID" ]; then
        echo "❌ Could not find CamillaDSP process"
        return 1
    fi
    
    echo "   Sending SIGHUP to PID $CAMILLADSP_PID"
    kill -HUP "$CAMILLADSP_PID"
    
    if [ $? -eq 0 ]; then
        echo "✓ SIGHUP signal sent successfully"
        echo "   Configuration should reload automatically"
        return 0
    else
        echo "❌ Failed to send SIGHUP signal"
        return 1
    fi
}

# Method 2: Service restart (more disruptive but reliable)
reload_with_restart() {
    echo "🔄 Reloading configuration by restarting service..."
    
    sudo systemctl restart "$SERVICE_NAME"
    
    if [ $? -eq 0 ]; then
        echo "✓ Service restarted successfully"
        sleep 2
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            echo "✓ Service is running with new configuration"
            return 0
        else
            echo "❌ Service failed to start with new configuration"
            echo "   Check logs: sudo journalctl -u $SERVICE_NAME -n 20"
            return 1
        fi
    else
        echo "❌ Failed to restart service"
        return 1
    fi
}

# Method 3: Websocket API (requires API to be enabled)
reload_with_websocket() {
    echo "🔄 Attempting to reload via websocket API..."
    
    # Check if API is accessible (basic connectivity test)
    if command -v curl >/dev/null 2>&1; then
        API_RESPONSE=$(curl -s --connect-timeout 3 http://localhost:1234/api/v1/state 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$API_RESPONSE" ]; then
            echo "✓ CamillaDSP API is accessible"
            echo "ℹ️  Manual API reload command:"
            echo "   Use the CamillaDSP GUI or websocket client to send reload command"
            echo "   API endpoint: http://localhost:1234"
            return 0
        else
            echo "❌ CamillaDSP API not accessible on port 1234"
            echo "   Make sure CamillaDSP was started with -p 1234 option"
            return 1
        fi
    else
        echo "⚠️  curl not available - cannot test API connectivity"
        echo "   Install curl: sudo apt install curl"
        return 1
    fi
}

# Parse command line arguments
METHOD=""
VALIDATE_FIRST=true

for arg in "$@"; do
    case $arg in
        --sighup)
            METHOD="sighup"
            ;;
        --restart)
            METHOD="restart"
            ;;
        --websocket)
            METHOD="websocket"
            ;;
        --no-validate)
            VALIDATE_FIRST=false
            ;;
        --help|-h)
            echo "Usage: $0 [method] [options]"
            echo
            echo "Methods:"
            echo "  --sighup      Use SIGHUP signal (recommended, fastest)"
            echo "  --restart     Restart systemd service (more disruptive)"
            echo "  --websocket   Show websocket API information"
            echo
            echo "Options:"
            echo "  --no-validate Skip configuration validation before reload"
            echo "  --help, -h    Show this help message"
            echo
            echo "Examples:"
            echo "  $0                    # Interactive mode"
            echo "  $0 --sighup           # Use SIGHUP method"
            echo "  $0 --restart          # Use service restart"
            echo "  $0 --sighup --no-validate  # Skip validation"
            exit 0
            ;;
    esac
done

# Validate configuration before reload (unless skipped)
if [ "$VALIDATE_FIRST" = "true" ]; then
    echo "🔍 Validating configuration before reload..."
    
    if command -v "/usr/local/bin/camilladsp" >/dev/null 2>&1; then
        VALIDATION_OUTPUT=$(/usr/local/bin/camilladsp -c "$CONFIG_FILE" 2>&1)
        VALIDATION_RESULT=$?
        
        if [ $VALIDATION_RESULT -eq 0 ]; then
            echo "✓ Configuration validation passed"
        else
            echo "❌ Configuration validation failed:"
            echo "$VALIDATION_OUTPUT"
            echo
            echo "Fix the configuration errors before reloading"
            exit 1
        fi
    else
        echo "⚠️  Cannot validate config - CamillaDSP binary not found"
        echo "   Proceeding without validation..."
    fi
    echo
fi

# Execute the chosen method
if [ -n "$METHOD" ]; then
    case "$METHOD" in
        sighup)
            reload_with_sighup
            ;;
        restart)
            reload_with_restart
            ;;
        websocket)
            reload_with_websocket
            ;;
        *)
            echo "❌ Unknown method: $METHOD"
            exit 1
            ;;
    esac
else
    # Interactive mode
    echo "Select reload method:"
    echo "1) SIGHUP signal (recommended)"
    echo "2) Service restart"  
    echo "3) Websocket API info"
    echo "q) Quit"
    echo
    read -p "Choose option (1-3, q): " choice
    
    case "$choice" in
        1)
            reload_with_sighup
            ;;
        2)
            reload_with_restart
            ;;
        3)
            reload_with_websocket
            ;;
        q|Q)
            echo "Cancelled"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
fi

RELOAD_RESULT=$?

echo
if [ $RELOAD_RESULT -eq 0 ]; then
    echo "🎉 Configuration reload completed successfully!"
    echo
    echo "Monitor the service:"
    echo "• Check status: systemctl status $SERVICE_NAME"
    echo "• View logs: sudo journalctl -u $SERVICE_NAME -f"
    echo "• Test audio: play audio to 'Pi Zero USB Audio' device"
else
    echo "❌ Configuration reload failed"
    echo
    echo "Troubleshooting:"
    echo "• Check service status: systemctl status $SERVICE_NAME"
    echo "• View error logs: sudo journalctl -u $SERVICE_NAME -n 20"
    echo "• Validate config: /usr/local/bin/camilladsp -c $CONFIG_FILE"
    echo "• Run debug script: ./debug-camilladsp.sh"
fi

exit $RELOAD_RESULT
