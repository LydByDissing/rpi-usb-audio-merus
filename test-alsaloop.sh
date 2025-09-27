#!/bin/bash
# Test alsaloop with exact device names

echo "=== Testing alsaloop directly ==="
echo

echo "1. Available devices:"
aplay -l

echo
echo "2. Testing alsaloop command step by step:"

# Kill existing
pkill alsaloop 2>/dev/null && echo "Killed existing alsaloop" || echo "No existing alsaloop"

echo
echo "3. Testing capture device (UAC2):"
echo "Command: arecord -D plughw:2,0 -f S16_LE -c 2 -r 48000 -t wav --max-file-time 1 /dev/null"
if timeout 2 arecord -D plughw:2,0 -f S16_LE -c 2 -r 48000 -t wav --max-file-time 1 /dev/null 2>/dev/null; then
    echo "✅ UAC2 capture device works"
else
    echo "❌ UAC2 capture device failed"
fi

echo
echo "4. Testing playback device (Merus):"
echo "Command: speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -c 2 -t wav -l 1"
if timeout 3 speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -c 2 -t wav -l 1 >/dev/null 2>&1; then
    echo "✅ Merus playback device works"
else
    echo "❌ Merus playback device failed"
fi

echo
echo "5. Starting alsaloop with verbose output:"
echo "Command: alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 -v"
echo "This will run for 10 seconds - play audio from host now!"

timeout 10 alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 -v || echo "alsaloop ended"

echo
echo "6. If that worked, starting in daemon mode:"
alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 -d &
ALSALOOP_PID=$!

sleep 1
if kill -0 $ALSALOOP_PID 2>/dev/null; then
    echo "✅ alsaloop started in daemon mode (PID: $ALSALOOP_PID)"
    echo "Audio routing active - test from host!"
    echo "To stop: pkill alsaloop"
else
    echo "❌ alsaloop daemon failed"
fi
