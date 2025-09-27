#!/bin/bash
# Debug why alsaloop is failing

echo "=== alsaloop Debug ==="
echo

echo "1. Audio devices:"
aplay -l
echo
arecord -l

echo
echo "2. Testing individual components:"

echo "Testing UAC2 capture device..."
echo "Command: arecord -D plughw:2,0 -f S16_LE -c 2 -r 48000 -t wav --max-file-time 1 /tmp/test.wav"
if timeout 3 arecord -D plughw:2,0 -f S16_LE -c 2 -r 48000 -t wav --max-file-time 1 /tmp/test.wav 2>&1; then
    echo "✅ UAC2 capture works"
    ls -la /tmp/test.wav 2>/dev/null && rm -f /tmp/test.wav
else
    echo "❌ UAC2 capture failed"
fi

echo
echo "Testing Merus playback device..."
echo "Command: speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -c 2 -t wav -l 1 -s 1"
if timeout 3 speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -c 2 -t wav -l 1 -s 1 >/dev/null 2>&1; then
    echo "✅ Merus playback works"
else
    echo "❌ Merus playback failed"
fi

echo
echo "3. Testing alsaloop with full error output:"
echo "Command: alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000"

# Try alsaloop with full error output
timeout 5 alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 2>&1 &
ALSALOOP_PID=$!

sleep 2
if kill -0 $ALSALOOP_PID 2>/dev/null; then
    echo "✅ alsaloop is running (PID: $ALSALOOP_PID)"
    sleep 3
    kill $ALSALOOP_PID 2>/dev/null
    echo "Stopped alsaloop test"
else
    echo "❌ alsaloop failed immediately"
fi

echo
echo "4. Testing simplified alsaloop:"
echo "Command: alsaloop -C hw:2,0 -P hw:1,0"
timeout 5 alsaloop -C hw:2,0 -P hw:1,0 2>&1 &
ALSALOOP_PID=$!

sleep 2
if kill -0 $ALSALOOP_PID 2>/dev/null; then
    echo "✅ Simplified alsaloop works (PID: $ALSALOOP_PID)"
    sleep 3
    kill $ALSALOOP_PID 2>/dev/null
    echo "Stopped simplified test"
else
    echo "❌ Simplified alsaloop also failed"
fi

echo
echo "5. Checking ALSA configuration:"
echo "Contents of /proc/asound/cards:"
cat /proc/asound/cards

echo
echo "6. Checking device capabilities:"
echo "UAC2 Gadget info:"
cat /proc/asound/card2/pcm0c/info 2>/dev/null || echo "No capture info for card2"
cat /proc/asound/card2/pcm0p/info 2>/dev/null || echo "No playback info for card2"

echo
echo "Merus amp info:"
cat /proc/asound/card1/pcm0p/info 2>/dev/null || echo "No playback info for card1"

echo
echo "=== Recommendations ==="
echo "If alsaloop is failing, try:"
echo "1. Simpler command: alsaloop -C hw:2,0 -P hw:1,0"
echo "2. Check permissions: run as root"
echo "3. Check if devices are busy: lsof /dev/snd/*"
