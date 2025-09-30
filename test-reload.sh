#!/bin/bash
# Quick test script to verify reload functionality
# This tests the config copy and reload logic

echo "=== Testing CamillaDSP Configuration Reload ==="
echo

LOCAL_CONFIG="./camilladsp.yml"
SYSTEM_CONFIG="/usr/local/etc/camilladsp.yml"

echo "📋 Current setup:"
echo "   Local config: $LOCAL_CONFIG $([ -f "$LOCAL_CONFIG" ] && echo '✓' || echo '❌')"
echo "   System config: $SYSTEM_CONFIG $([ -f "$SYSTEM_CONFIG" ] && echo '✓' || echo '❌')"

if [ -f "$LOCAL_CONFIG" ]; then
    echo
    echo "🔍 Local config content (last 5 lines):"
    tail -5 "$LOCAL_CONFIG" | sed 's/^/   /'
fi

if [ -f "$SYSTEM_CONFIG" ]; then
    echo
    echo "🔍 System config content (last 5 lines):"
    sudo tail -5 "$SYSTEM_CONFIG" 2>/dev/null | sed 's/^/   /' || echo "   ❌ Cannot read system config"
fi

echo
echo "🎯 Next steps:"
echo "   1. Edit $LOCAL_CONFIG with your changes"
echo "   2. Run ./reload-config.sh to copy and reload"
echo "   3. Changes should take effect immediately"
echo
echo "💡 The reload script will:"
echo "   - Copy $LOCAL_CONFIG to $SYSTEM_CONFIG" 
echo "   - Send SIGHUP to CamillaDSP process"
echo "   - Verify the configuration was applied"
