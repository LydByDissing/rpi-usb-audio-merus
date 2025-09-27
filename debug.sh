#!/bin/bash
# Debug script to find why USB gadget isn't working

echo "=== USB Gadget Debug Analysis ==="
echo

echo "1. Service Status:"
if systemctl is-active --quiet usb-gadget-audio.service; then
    echo "   ✅ usb-gadget-audio.service is running"
else
    echo "   ❌ usb-gadget-audio.service is NOT running"
    echo "   Status: $(systemctl is-active usb-gadget-audio.service)"
fi

echo "   Service logs (last 10 lines):"
journalctl -u usb-gadget-audio.service -n 10 --no-pager | while read line; do
    echo "     $line"
done

echo

echo "2. Required Kernel Modules:"
echo "   dwc2: $(lsmod | grep dwc2 >/dev/null && echo "✅ loaded" || echo "❌ not loaded")"
echo "   libcomposite: $(lsmod | grep libcomposite >/dev/null && echo "✅ loaded" || echo "❌ not loaded")"

if ! lsmod | grep dwc2 >/dev/null; then
    echo "   → Trying to load dwc2..."
    sudo modprobe dwc2 && echo "   ✅ dwc2 loaded" || echo "   ❌ dwc2 failed to load"
fi

if ! lsmod | grep libcomposite >/dev/null; then
    echo "   → Trying to load libcomposite..."
    sudo modprobe libcomposite && echo "   ✅ libcomposite loaded" || echo "   ❌ libcomposite failed to load"
fi

echo

echo "3. Boot Configuration:"
echo "   /boot/config.txt check:"
if grep -q "dtoverlay=dwc2" /boot/config.txt; then
    echo "   ✅ dtoverlay=dwc2 found"
else
    echo "   ❌ dtoverlay=dwc2 missing"
fi

echo "   /etc/modules check:"
if grep -q "dwc2" /etc/modules; then
    echo "   ✅ dwc2 in /etc/modules"
else
    echo "   ❌ dwc2 missing from /etc/modules"
fi

if grep -q "libcomposite" /etc/modules; then
    echo "   ✅ libcomposite in /etc/modules"
else
    echo "   ❌ libcomposite missing from /etc/modules"
fi

echo

echo "4. USB Device Controller:"
if [ -d "/sys/class/udc" ]; then
    echo "   Available UDCs:"
    ls /sys/class/udc/ | while read udc; do
        echo "     $udc"
    done
else
    echo "   ❌ No UDCs found in /sys/class/udc"
fi

echo

echo "5. ConfigFS Mount:"
if mountpoint -q /sys/kernel/config; then
    echo "   ✅ ConfigFS is mounted"
else
    echo "   ❌ ConfigFS is not mounted"
    echo "   → Trying to mount..."
    sudo mount -t configfs none /sys/kernel/config && echo "   ✅ ConfigFS mounted" || echo "   ❌ ConfigFS mount failed"
fi

echo

echo "6. USB Gadget Directory:"
GADGET_DIR="/sys/kernel/config/usb_gadget/pi_audio"
if [ -d "$GADGET_DIR" ]; then
    echo "   ✅ Gadget directory exists: $GADGET_DIR"
    
    if [ -f "$GADGET_DIR/UDC" ]; then
        UDC_CONTENT=$(cat "$GADGET_DIR/UDC")
        if [ -n "$UDC_CONTENT" ]; then
            echo "   ✅ UDC binding: $UDC_CONTENT"
        else
            echo "   ⚠️  UDC file exists but is empty"
        fi
    else
        echo "   ❌ UDC file missing"
    fi
else
    echo "   ❌ Gadget directory does not exist"
fi

echo

echo "7. Manual USB Gadget Test:"
echo "   Let's try to manually configure the USB gadget..."

# Try to run the gadget script manually
if [ -f "/usr/local/bin/usb-gadget-audio.sh" ]; then
    echo "   Running USB gadget script manually..."
    echo "   (This may show error messages that help diagnose the issue)"
    echo
    sudo /usr/local/bin/usb-gadget-audio.sh
    echo
else
    echo "   ❌ USB gadget script not found at /usr/local/bin/usb-gadget-audio.sh"
fi

echo

echo "8. Kernel Messages:"
echo "   Recent kernel messages (last 15 lines):"
dmesg | tail -15 | while read line; do
    echo "     $line"
done

echo

echo "=== Recommended Actions ==="
if ! systemctl is-active --quiet usb-gadget-audio.service; then
    echo "1. Start the service: sudo systemctl start usb-gadget-audio.service"
fi

if ! lsmod | grep dwc2 >/dev/null || ! lsmod | grep libcomposite >/dev/null; then
    echo "2. Check if you need to reboot after running ./install.sh"
fi

if ! grep -q "dtoverlay=dwc2" /boot/config.txt; then
    echo "3. Re-run ./install.sh to fix configuration"
fi

echo "4. If still not working, try: sudo reboot"
echo "5. After reboot, run ./check-pi-side.sh again"
