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
LOCAL_CONFIG_FILE="./camilladsp.yml"
SERVICE_NAME="camilladsp.service"

# Copy local config to system location if it exists
copy_config_if_needed() {
    if [ -f "$LOCAL_CONFIG_FILE" ]; then
        echo "🔄 Copying local configuration to system location..."
        
        # Always copy to ensure latest changes are used
        sudo cp "$LOCAL_CONFIG_FILE" "$CONFIG_FILE"
        if [ $? -eq 0 ]; then
            echo "✓ Configuration updated: $LOCAL_CONFIG_FILE → $CONFIG_FILE"
            return 0
        else
            echo "❌ Failed to copy configuration file"
            return 1
        fi
    else
        echo "ℹ️  No local config file found, using existing system config"
    fi
    return 0
}

# Enhanced verification function
verify_config_applied() {
    echo "🔍 Verifying configuration was applied..."
    
    # Method 1: Check API if available
    if command -v curl >/dev/null 2>&1; then
        API_CONFIG=$(curl -s --connect-timeout 2 http://localhost:1234/api/v1/config 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$API_CONFIG" ]; then
            # Check if our filter is in the active config
            if echo "$API_CONFIG" | grep -q "bass_shelf_120hz"; then
                echo "✓ Filter 'bass_shelf_120hz' confirmed in active configuration via API"
                
                # Try to extract gain value
                GAIN_VALUE=$(echo "$API_CONFIG" | grep -A 3 "bass_shelf_120hz" | grep -o '"gain":[^,]*' | cut -d: -f2 | tr -d ' ' 2>/dev/null)
                if [ -n "$GAIN_VALUE" ]; then
                    echo "✓ Filter gain setting: ${GAIN_VALUE}dB"
                fi
                return 0
            else
                echo "⚠️  Filter 'bass_shelf_120hz' not found in active API configuration"
                return 1
            fi
        fi
    fi
    
    # Method 2: Check file modification time vs process start time
    CONFIG_MTIME=$(stat -c %Y /usr/local/etc/camilladsp.yml 2>/dev/null || echo "0")
    PROCESS_START=$(ps -o lstart= -p $(pgrep -f "/usr/local/bin/camilladsp") 2>/dev/null | head -1)
    
    if [ -n "$PROCESS_START" ]; then
        echo "ℹ️  Process started: $PROCESS_START"
        echo "ℹ️  Config modified: $(date -d @$CONFIG_MTIME 2>/dev/null || echo 'unknown')"
    fi
    
    # Method 3: Check recent logs for reload activity
    RELOAD_LOGS=$(journalctl -u camilladsp.service --since "1 minute ago" --no-pager -q 2>/dev/null)
    if echo "$RELOAD_LOGS" | grep -q -i "reload\|configuration\|config"; then
        echo "✓ Recent reload activity detected in logs"
        return 0
    else
        echo "ℹ️  No explicit reload confirmation available"
        echo "   Try testing audio to confirm filter is working"
        return 2  # Uncertain but not failed
    fi
}

# Always copy config first before any operations
echo "🔍 Preparing configuration..."
copy_config_if_needed
if [ $? -ne 0 ]; then
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    echo "   Make sure you have either:"
    echo "   - Local config: $LOCAL_CONFIG_FILE"
    echo "   - System config: $CONFIG_FILE"
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
        echo "   Service might not be running. Try: sudo systemctl start camilladsp"
        return 1
    fi
    
    echo "   Sending SIGHUP to PID $CAMILLADSP_PID"
    kill -HUP "$CAMILLADSP_PID"
    
    if [ $? -eq 0 ]; then
        echo "✓ SIGHUP signal sent successfully"
        
        # Give CamillaDSP a moment to reload
        echo "   Waiting for configuration reload..."
        sleep 2
        
        # Verify the process is still running after reload
        if pgrep -f "/usr/local/bin/camilladsp" >/dev/null; then
            echo "✓ CamillaDSP process is still running after reload"
            
            # Check if the service shows any recent restart activity
            RECENT_LOGS=$(journalctl -u camilladsp.service --since "30 seconds ago" --no-pager -q)
            if echo "$RECENT_LOGS" | grep -q "reload\|config"; then
                echo "✓ Configuration reload confirmed in logs"
            else
                echo "ℹ️  No reload confirmation in logs (this may be normal)"
            fi
            
            # Wait a moment for config to fully apply
            sleep 1
            
            # Additional verification
            verify_config_applied
            return 0
        else
            echo "❌ CamillaDSP process died after SIGHUP - config might have errors"
            echo "   Check logs: sudo journalctl -u camilladsp -n 10"
            return 1
        fi
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
        --interactive|-i)
            METHOD="interactive"
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
            echo "  --interactive, -i  Interactive mode with menu selection"
            echo
            echo "Options:"
            echo "  --no-validate Skip configuration validation before reload"
            echo "  --help, -h    Show this help message"
            echo
            echo "Examples:"
            echo "  $0                    # Default: SIGHUP reload"
            echo "  $0 --sighup           # Explicit SIGHUP method"
            echo "  $0 --interactive      # Interactive menu"
            echo "  $0 --restart          # Service restart"
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
        interactive)
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
            ;;
        *)
            echo "❌ Unknown method: $METHOD"
            exit 1
            ;;
    esac
else
    # Default mode: Use SIGHUP (fastest and most reliable)
    echo "Using default method: SIGHUP signal reload"
    echo
    reload_with_sighup
fi

RELOAD_RESULT=$?

# Final status message
echo
if [ $RELOAD_RESULT -eq 0 ]; then
    echo "🎉 Configuration reload completed successfully!"
    echo "   Your audio processing changes are now active."
    echo "   Test with audio playback to verify the new settings."
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
