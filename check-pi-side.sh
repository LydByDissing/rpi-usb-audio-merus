#!/bin/bash
# Check USB gadget connectivity from Pi side

echo "=== Pi-Side USB Gadget Connectivity Check ==="
echo

echo "1. USB Controller Status:"
USB_STATE_FILE="/sys/devices/platform/soc/20980000.usb/dwc2/udc/20980000.usb/state"
if [ -f "$USB_STATE_FILE" ]; then
    USB_STATE=$(cat "$USB_STATE_FILE" 2>/dev/null || echo "unknown")
    echo "   Current state: $USB_STATE"
    
    case "$USB_STATE" in
        "not connected")
            echo "   ❌ No host connection detected"
            echo "   → Check cable, port, or host machine"
            ;;
        "powered")
            echo "   🔋 Host detected, but enumeration incomplete"
            echo "   → Host sees device but hasn't configured it yet"
            ;;
        "default"|"addressed")
            echo "   🔄 Enumeration in progress"
            echo "   → Host is communicating with device"
            ;;
        "configured")
            echo "   ✅ Fully connected and configured!"
            echo "   → Device should appear on host"
            ;;
        "suspended")
            echo "   😴 Connection suspended (host may be sleeping)"
            ;;
        *)
            echo "   ⚠️  Unknown state: $USB_STATE"
            ;;
    esac
else
    echo "   ❌ USB controller state file not found"
    echo "   → USB gadget may not be configured"
fi

echo

echo "2. USB Gadget Configuration:"
GADGET_DIR="/sys/kernel/config/usb_gadget/pi_audio"
if [ -d "$GADGET_DIR" ]; then
    echo "   ✅ USB gadget configured"
    
    # Check UDC binding
    if [ -f "$GADGET_DIR/UDC" ]; then
        UDC_BINDING=$(cat "$GADGET_DIR/UDC" 2>/dev/null)
        if [ -n "$UDC_BINDING" ]; then
            echo "   ✅ Bound to UDC: $UDC_BINDING"
        else
            echo "   ❌ Not bound to any UDC"
        fi
    fi
    
    # Check function
    if [ -d "$GADGET_DIR/functions/uac2.usb0" ]; then
        echo "   ✅ UAC2 function present"
        echo "     • Sample rate: $(cat "$GADGET_DIR/functions/uac2.usb0/p_srate" 2>/dev/null)Hz"
        echo "     • Channels: $(cat "$GADGET_DIR/functions/uac2.usb0/p_chmask" 2>/dev/null)"
    else
        echo "   ❌ UAC2 function missing"
    fi
else
    echo "   ❌ USB gadget not configured"
fi

echo

echo "3. Kernel Messages (last 10 USB-related):"
dmesg | grep -i usb | tail -10 | while read line; do
    echo "   $line"
done

echo

echo "4. USB Audio Devices:"
echo "   ALSA playback devices:"
aplay -l 2>/dev/null | grep -E "(card|UAC2)" | while read line; do
    echo "     $line"
done

echo

echo "5. Network Connectivity Test:"
echo "   You can also test from host by connecting to Pi via SSH/network"
echo "   and running this script remotely to monitor connection status."

echo

echo "6. Real-time Monitoring:"
echo "   To watch connection state changes in real-time:"
echo "   watch -n 1 'cat $USB_STATE_FILE 2>/dev/null || echo \"not available\"'"

echo

echo "7. USB Power Detection:"
USB_POWER="/sys/devices/platform/soc/20980000.usb/dwc2/udc/20980000.usb/power"
if [ -d "$USB_POWER" ]; then
    echo "   USB power management available"
    if [ -f "$USB_POWER/runtime_status" ]; then
        PWR_STATUS=$(cat "$USB_POWER/runtime_status" 2>/dev/null || echo "unknown")
        echo "   Power state: $PWR_STATUS"
    fi
else
    echo "   USB power information not available"
fi

echo

echo "=== Connection States Explained ==="
echo "not connected → powered → default → addressed → configured"
echo "     ↑              ↑         ↑         ↑           ↑"
echo "  No cable    Cable plug  Host sees  Host gets   Ready!"
echo "              detected    device     address"
