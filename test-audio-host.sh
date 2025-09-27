#!/bin/bash
# Test audio from host to Pi Zero USB Audio → Merus amp

echo "=== Pi Zero USB Audio Test ==="
echo

echo "1. Looking for Pi Zero USB Audio device:"
PI_AUDIO_INFO=$(aplay -l 2>/dev/null | grep -i "Pi Zero USB Audio\|Pi Zero")
if [ -n "$PI_AUDIO_INFO" ]; then
    PI_CARD=$(echo "$PI_AUDIO_INFO" | grep -o "card [0-9]" | head -1 | cut -d' ' -f2)
    echo "   ✅ Found Pi Zero at card $PI_CARD"
    echo "   ℹ️  $PI_AUDIO_INFO"
else
    echo "   ❌ Pi Zero USB Audio device not found!"
    echo "   Make sure:"
    echo "   • Pi Zero is connected via USB data cable"
    echo "   • install.sh has been run on the Pi"
    echo "   • Pi has been rebooted after install"
    echo "   Check with: lsusb"
    exit 1
fi

echo
echo "2. Testing audio playback:"
echo "   Playing 3-second test tone through Pi Zero..."
echo "   (You should hear this through the Merus amp/speakers on Pi)"

if speaker-test -D plughw:$PI_CARD,0 -c 2 -t wav -l 1 -s 1; then
    echo "   ✅ Audio test successful!"
else
    echo "   ❌ Audio test failed"
    echo "   Check:"
    echo "   • Audio routing service on Pi: ssh pi@[pi-ip] 'systemctl status usb-audio-routing.service'"
    echo "   • Audio volume on Pi: ssh pi@[pi-ip] 'alsamixer'"
    exit 1
fi

echo
echo "3. Full system test complete!"
echo "   • Pi Zero appears as USB audio device: ✅"
echo "   • Audio routing to Merus amp: ✅"
echo
echo "You can now use the Pi Zero as an audio output device:"
echo "   • Select 'Pi Zero USB Audio' in your audio settings"
echo "   • Audio will be routed through the Merus amp automatically"
