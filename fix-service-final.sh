#!/bin/bash
# Fix the systemd service to work like manual alsaloop

echo "=== Fixing Audio Routing Service ==="
echo

echo "1. Creating improved service configuration..."

# Create a better service that runs alsaloop directly
sudo tee /etc/systemd/system/usb-audio-routing.service > /dev/null << 'EOF'
[Unit]
Description=USB to Merus Amp Audio Routing
After=usb-gadget-audio.service sound.target
Requires=usb-gadget-audio.service
StartLimitIntervalSec=30
StartLimitBurst=5

[Service]
Type=simple
ExecStartPre=/bin/sleep 10
ExecStartPre=/usr/bin/pkill -f alsaloop
ExecStart=/usr/bin/alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000
Restart=on-failure
RestartSec=10
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Created improved service file"

echo
echo "2. Reloading systemd..."
sudo systemctl daemon-reload

echo
echo "3. Enabling service..."
sudo systemctl enable usb-audio-routing.service

echo
echo "4. Starting service..."
if sudo systemctl start usb-audio-routing.service; then
    echo "✅ Service started"
else
    echo "❌ Service failed to start"
    echo "Checking logs:"
    journalctl -u usb-audio-routing.service -n 5 --no-pager
    exit 1
fi

echo
echo "5. Checking service status (waiting 15 seconds)..."
sleep 15

if systemctl is-active --quiet usb-audio-routing.service; then
    echo "✅ Service is running successfully"
    
    if pgrep alsaloop >/dev/null; then
        echo "✅ alsaloop is active (PID: $(pgrep alsaloop))"
        echo "🎵 Audio routing should be working!"
        echo
        echo "Test from your host - play audio to 'Pi Zero USB Audio' device"
    else
        echo "❌ Service running but no alsaloop process"
    fi
else
    echo "❌ Service failed after 15 seconds"
    echo "Status:"
    systemctl status usb-audio-routing.service --no-pager -l
    echo
    echo "Recent logs:"
    journalctl -u usb-audio-routing.service -n 10 --no-pager
fi

echo
echo "6. Service will auto-start on boot"
echo "   To check: systemctl status usb-audio-routing.service"
echo "   To stop:  sudo systemctl stop usb-audio-routing.service"
echo "   Manual:   ./start-routing.sh"
