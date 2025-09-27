#!/bin/bash
# Debug audio flow from host to Pi

echo "=== Audio Flow Debug ==="
echo

echo "HOST SIDE:"
echo "1. Pi Zero USB device detection:"
lsusb | grep -i "audio\|gadget\|pi\|zero" || echo "   No obvious Pi Zero USB device found"

echo
echo "2. ALSA devices with Pi Zero:"
aplay -l | grep -A2 -B1 -i "pi zero\|audio.*usb" || echo "   No Pi Zero audio device found"

echo
echo "3. Testing host → Pi USB audio:"
PI_CARD=$(aplay -l 2>/dev/null | grep -i "Pi Zero USB Audio\|Pi Zero\|Audio.*USB" | grep -o "card [0-9]" | head -1 | cut -d' ' -f2)
if [ -n "$PI_CARD" ]; then
    echo "   Found Pi Zero at card $PI_CARD"
    echo "   Testing with 1-second tone..."
    timeout 2 speaker-test -D plughw:$PI_CARD,0 -c 2 -t wav -l 1 -s 1 2>/dev/null && echo "   ✅ Host audio test successful" || echo "   ❌ Host audio test failed"
else
    echo "   ❌ Pi Zero audio device not found on host"
fi

echo
echo "HOST PULSEAUDIO/PIPEWIRE CHECK:"
echo "4. Available sinks:"
if command -v pactl >/dev/null 2>&1; then
    pactl list short sinks | grep -i "usb\|pi\|zero" || echo "   No USB/Pi audio sinks found"
    echo
    echo "5. Current default sink:"
    pactl get-default-sink
else
    echo "   PulseAudio not available"
fi

echo
echo "=== Instructions ==="
echo "Run this on your PI to check the Pi side:"
echo "ssh pi@[your-pi-ip] 'pgrep alsaloop && echo \"Routing active\" || echo \"Routing NOT active\"'"
echo
echo "If routing not active on Pi, run: ./start-routing.sh"
