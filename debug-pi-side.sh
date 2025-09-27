#!/bin/bash
# Debug Pi-side audio routing

echo "=== Pi-Side Audio Debug ==="
echo

echo "1. Audio devices on Pi:"
aplay -l

echo
echo "2. USB gadget service status:"
systemctl status usb-gadget-audio.service --no-pager -l

echo
echo "3. Audio routing service status:"
systemctl status usb-audio-routing.service --no-pager -l

echo
echo "4. Check for running alsaloop:"
if pgrep alsaloop >/dev/null; then
    echo "   ✅ alsaloop is running"
    echo "   PIDs: $(pgrep alsaloop)"
    echo "   Process details:"
    ps aux | grep alsaloop | grep -v grep
else
    echo "   ❌ alsaloop is NOT running"
fi

echo
echo "5. Audio device verification:"
# Check UAC2 Gadget
if aplay -l 2>/dev/null | grep -q "UAC2_Gadget.*card 2"; then
    echo "   ✅ UAC2_Gadget found at card 2"
else
    echo "   ❌ UAC2_Gadget not found at expected card 2"
fi

# Check Merus amp
if aplay -l 2>/dev/null | grep -q "sndrpimerusamp.*card 1"; then
    echo "   ✅ Merus amp found at card 1"
else
    echo "   ❌ Merus amp not found at expected card 1"
fi

echo
echo "6. Test UAC2 gadget capture (should show activity when host plays audio):"
echo "   Testing for 3 seconds... play audio from host NOW"
timeout 3 arecord -D plughw:2,0 -f S16_LE -c 2 -r 48000 /dev/null 2>&1 && echo "   ✅ UAC2 capture working" || echo "   ❌ UAC2 capture failed"

echo
echo "7. Manual routing test:"
echo "   Killing any existing alsaloop..."
pkill alsaloop 2>/dev/null || true
sleep 1

echo "   Starting manual routing: UAC2 → Merus"
echo "   Command: alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 -d"
alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 -d &
ALSALOOP_PID=$!

sleep 2
if kill -0 $ALSALOOP_PID 2>/dev/null; then
    echo "   ✅ Manual routing started successfully (PID: $ALSALOOP_PID)"
    echo "   Try playing audio from host now!"
    echo "   To stop: pkill alsaloop"
else
    echo "   ❌ Manual routing failed to start"
fi

echo
echo "8. Service logs (last 10 lines):"
echo "   USB Gadget service:"
journalctl -u usb-gadget-audio.service -n 5 --no-pager | tail -5

echo "   Audio Routing service:"
journalctl -u usb-audio-routing.service -n 5 --no-pager | tail -5
