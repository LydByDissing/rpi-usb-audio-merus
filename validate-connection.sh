#!/bin/bash
# Script to validate USB cable and connection

echo "=== USB Connection Validation ==="
echo

echo "1. Physical Port Check:"
echo "   ✓ Use the micro USB port closest to the CENTER of the Pi Zero W"
echo "   ✗ Do NOT use the port closest to the EDGE (power-only port)"
echo "   📍 The correct port is labeled 'USB' on the board"
echo

echo "2. Cable Type Validation:"
echo "   Testing if cable supports data transfer..."
echo

# Check if we're in gadget mode
if [ -f "/sys/devices/platform/soc/20980000.usb/dwc2/udc/20980000.usb/state" ]; then
    USB_STATE=$(cat /sys/devices/platform/soc/20980000.usb/dwc2/udc/20980000.usb/state 2>/dev/null || echo "unknown")
    echo "   USB Controller State: $USB_STATE"
    
    case "$USB_STATE" in
        "not connected"|"unknown")
            echo "   ❌ No data connection detected"
            echo "   → Check: Cable might be power-only OR wrong port"
            ;;
        "connected"|"configured"|"addressed")
            echo "   ✅ Data connection active"
            ;;
        *)
            echo "   ⚠️  Connection state: $USB_STATE"
            ;;
    esac
else
    echo "   ❌ USB controller state file not found"
fi

echo

echo "3. Host Detection Test:"
echo "   Run these commands on the HOST machine:"
echo
echo "   # Before connecting Pi:"
echo "   lsusb > before.txt"
echo
echo "   # After connecting Pi:"
echo "   lsusb > after.txt"
echo "   diff before.txt after.txt"
echo
echo "   Expected result: New device with Vendor ID 1d6b should appear"
echo

echo "4. Pi-side Verification:"
echo "   USB Gadget Status:"
if [ -d "/sys/kernel/config/usb_gadget/pi_audio" ]; then
    UDC_CONTENT=$(cat /sys/kernel/config/usb_gadget/pi_audio/UDC 2>/dev/null || echo "empty")
    if [ "$UDC_CONTENT" != "empty" ] && [ -n "$UDC_CONTENT" ]; then
        echo "   ✅ Gadget bound to UDC: $UDC_CONTENT"
    else
        echo "   ❌ Gadget not bound to UDC"
    fi
else
    echo "   ❌ USB gadget not configured"
fi

echo

echo "5. Cable Testing Methods:"
echo "   Method 1 - Try a different cable:"
echo "   • Use a cable you KNOW works for data (e.g., phone sync cable)"
echo "   • Avoid cables that came with power banks or chargers"
echo
echo "   Method 2 - Test with another device first:"
echo "   • Connect an Android phone to your host with the same cable"
echo "   • If phone shows 'USB for file transfer', cable is good"
echo
echo "   Method 3 - Check cable markings:"
echo "   • Look for 'data' or 'sync' markings on cable"
echo "   • Charging-only cables are often thinner"
echo

echo "6. Host Machine Commands to Run:"
echo "   Linux host:"
echo "   sudo dmesg -w  # Watch for USB connection messages"
echo "   lsusb -v | grep -A5 -B5 1d6b  # Look for Pi device"
echo
echo "   Windows host:"
echo "   # Device Manager → Sound, video and game controllers"
echo "   # Should show 'Pi Zero USB Audio' or similar"
echo

echo "7. USB Hub Compatibility:"
echo "   ❌ USB hubs are NOT recommended for gadget mode"
echo "   ❌ Most hubs will NOT work with USB gadgets"
echo
echo "   Why hubs don't work:"
echo "   • USB gadgets need direct host controller connection"
echo "   • Hubs add extra enumeration complexity"
echo "   • Power delivery issues through hubs"
echo "   • Hub firmware may not support gadget descriptors"
echo
echo "   ✅ ALWAYS connect Pi DIRECTLY to host USB port"
echo "   ✅ Use built-in USB ports on your computer/laptop"
echo "   ❌ Avoid: USB hubs, docking stations, KVM switches"
echo

echo "=== Quick Test Procedure ==="
echo "1. Run this script with Pi disconnected"
echo "2. Note the USB state"  
echo "3. Connect Pi DIRECTLY to host (no hub!)"
echo "4. Wait 10 seconds"
echo "5. Run this script again"
echo "6. Compare USB states - should change from 'not connected'"
