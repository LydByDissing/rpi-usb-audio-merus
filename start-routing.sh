#!/bin/bash
# Quick script to start audio routing with correct settings

echo "Starting audio routing: USB → Merus Amp"
echo "UAC2_Gadget (card 2) → sndrpimerusamp (card 1)"

# Kill any existing routing
pkill alsaloop 2>/dev/null && echo "Stopped existing routing"

# Start routing (exact same command as systemd service)
alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 -d &

ALSALOOP_PID=$!
echo "Audio routing started with PID: $ALSALOOP_PID"
echo
echo "Routing: UAC2_Gadget (card 2) → sndrpimerusamp"
echo "To stop: pkill alsaloop"
echo
echo "Now test from your host by playing audio to 'Pi Zero USB Audio' device"
