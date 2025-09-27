#!/bin/bash
# Check for Merus Audio HAT and USB gadget compatibility

echo "=== Audio HAT Compatibility Check ==="
echo

echo "1. Detecting Audio Hardware:"
echo "   All audio cards detected:"
aplay -l 2>/dev/null | grep -E "card [0-9]" | while read line; do
    echo "     $line"
done

echo

echo "2. Checking for Merus HAT:"
MERUS_DETECTED=false
if aplay -l 2>/dev/null | grep -i merus >/dev/null; then
    echo "   ✅ Merus HAT detected"
    MERUS_DETECTED=true
elif aplay -l 2>/dev/null | grep -i "ma120x0p" >/dev/null; then
    echo "   ✅ Merus HAT (MA120x0P) detected" 
    MERUS_DETECTED=true
elif aplay -l 2>/dev/null | grep -E "card [0-9].*device [0-9]" | grep -v UAC2 >/dev/null; then
    echo "   ⚠️  Non-UAC2 audio device found (possibly Merus HAT)"
    MERUS_DETECTED=true
else
    echo "   ❓ No obvious Merus HAT detected"
fi

echo

echo "3. Device Tree Overlays Check:"
if [ -f "/boot/config.txt" ]; then
    echo "   Active audio overlays in /boot/config.txt:"
    grep -E "dtoverlay.*(audio|sound|dac|amp|merus|ma120)" /boot/config.txt 2>/dev/null | while read line; do
        echo "     $line"
    done
    
    if grep -q "dtoverlay.*merus\|dtoverlay.*ma120" /boot/config.txt 2>/dev/null; then
        echo "   ✅ Merus overlay detected in config"
    fi
fi

echo

echo "4. USB vs HAT Compatibility:"
echo "   🤔 IMPORTANT: USB gadget and audio HAT can COEXIST!"
echo
echo "   How it works:"
echo "   • USB gadget creates a VIRTUAL audio device (UAC2_Gadget)"
echo "   • Physical HAT remains available as separate audio device"
echo "   • You can route audio between them using ALSA"
echo
echo "   Example audio routing:"
echo "   • USB input (from host) → Route to HAT output"
echo "   • HAT input → Route to USB output (to host)"

echo

echo "5. Current Audio Routing Check:"
echo "   Default audio output:"
if command -v raspi-config >/dev/null 2>&1; then
    # Try to get current audio output setting
    echo "     Use 'sudo raspi-config' → Advanced → Audio to change"
else
    echo "     Check with: amixer scontrols"
fi

echo

echo "6. Potential Issues & Solutions:"
if [ "$MERUS_DETECTED" = true ]; then
    echo "   ✅ HAT detected - here's what to consider:"
    echo
    echo "   Power consumption:"
    echo "   • HAT + USB gadget may need more power"
    echo "   • Ensure adequate power supply (≥2.5A recommended)"
    echo
    echo "   Audio conflicts:"
    echo "   • No direct conflicts expected"
    echo "   • Both devices should appear in 'aplay -l'"
    echo "   • Use ALSA to route between USB and HAT"
    echo
    echo "   Testing:"
    echo "   • Test HAT: speaker-test -D plughw:0,0"
    echo "   • Test USB: speaker-test -D plughw:1,0"
    echo "     (adjust card numbers based on 'aplay -l' output)"
else
    echo "   ❓ No HAT conflicts detected"
fi

echo

echo "7. Audio Routing Examples:"
echo "   Route USB input to HAT output:"
echo "   alsaloop -C hw:1,0 -P hw:0,0 &"
echo
echo "   Route HAT input to USB output:"  
echo "   alsaloop -C hw:0,0 -P hw:1,0 &"
echo
echo "   (Adjust card numbers based on your 'aplay -l' output)"

echo

echo "8. Disable USB Audio (if needed):"
echo "   To temporarily disable USB audio gadget:"
echo "   sudo systemctl stop usb-gadget-audio.service"
echo
echo "   To permanently disable:"
echo "   sudo systemctl disable usb-gadget-audio.service"
echo "   ./cleanup.sh"
