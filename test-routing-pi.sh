#!/bin/bash
# Test audio routing on Pi Zero with current device configuration

echo "=== Pi Audio Routing Test ==="
echo

echo "1. Current audio devices:"
aplay -l

echo
echo "2. Device analysis:"

# Check for UAC2 Gadget
UAC2_CARD=""
if aplay -l 2>/dev/null | grep -q "card 2.*UAC2_Gadget"; then
    UAC2_CARD="2"
    echo "   ✅ UAC2_Gadget found at card $UAC2_CARD"
else
    echo "   ❌ UAC2_Gadget not found"
fi

# Check for Merus amp
MERUS_CARD=""
if aplay -l 2>/dev/null | grep -q "card 1.*merus\|card 1.*ma120x0p"; then
    MERUS_CARD="1"
    echo "   ✅ Merus amp found at card $MERUS_CARD"
else
    echo "   ❌ Merus amp not found"
fi

echo

if [ -n "$UAC2_CARD" ] && [ -n "$MERUS_CARD" ]; then
    echo "3. Testing Merus amp output:"
    echo "   Playing 2-second test tone on Merus amp..."
    echo "   Command: speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -f S32_LE -c 2"
    if timeout 5 speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -f S32_LE -c 2 -t wav -l 1; then
        echo "   ✅ Merus amp test successful"
    else
        echo "   ❌ Merus amp test failed - trying without format specification..."
        if timeout 5 speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -c 2 -t wav -l 1; then
            echo "   ✅ Merus amp works with default format"
        else
            echo "   ❌ Merus amp test still failed"
        fi
    fi

    echo
    echo "4. Setting up audio routing:"
    echo "   Routing: UAC2 (card $UAC2_CARD) → Merus (card $MERUS_CARD)"
    
    # Kill existing routing
    pkill alsaloop 2>/dev/null || true
    
    # Start routing (let ALSA handle format conversion)
    if alsaloop -C plughw:$UAC2_CARD,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 -d; then
        echo "   ✅ Audio routing started successfully"
        echo "   PID: $(pgrep alsaloop)"
    else
        echo "   ❌ Failed to start audio routing"
    fi

    echo
    echo "5. Audio routing is now active!"
    echo "   • Audio from host USB → Pi UAC2 → Merus amp"
    echo "   • Test from host by playing audio to 'Pi Zero USB Audio' device"
    echo
    echo "To stop routing: pkill alsaloop"
    
else
    echo "❌ Cannot set up routing - missing devices"
    echo "   UAC2_CARD: $UAC2_CARD"
    echo "   MERUS_CARD: $MERUS_CARD"
fi
