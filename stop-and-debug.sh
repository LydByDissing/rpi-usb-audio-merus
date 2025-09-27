#!/bin/bash
# Stop the problematic service and debug alsaloop

echo "=== Stop Service and Debug ==="
echo

echo "1. Stopping the restarting service..."
sudo systemctl stop usb-audio-routing.service
sudo systemctl disable usb-audio-routing.service
echo "✅ Service stopped and disabled"

echo
echo "2. Kill any running alsaloop processes..."
sudo pkill alsaloop
echo "✅ Cleared alsaloop processes"

echo
echo "3. Running alsaloop debug..."
./debug-alsaloop.sh

echo
echo "=== Manual Test ==="
echo "If debug shows alsaloop can work, try manual start:"
echo "  sudo alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 -d"
echo
echo "Or try the working version from debug and then run:"
echo "  ./start-routing.sh"
