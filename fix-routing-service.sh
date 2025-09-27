#!/bin/bash
# Fix and enable the audio routing service

echo "=== Fixing Audio Routing Service ==="
echo

echo "1. Current service status:"
systemctl status usb-audio-routing.service --no-pager -l || echo "Service not found"

echo
echo "2. Checking if service file exists:"
if [ -f "/etc/systemd/system/usb-audio-routing.service" ]; then
    echo "✅ Service file exists"
    echo "Content:"
    cat /etc/systemd/system/usb-audio-routing.service
else
    echo "❌ Service file missing - creating it..."
    
    sudo tee /etc/systemd/system/usb-audio-routing.service > /dev/null << 'EOF'
[Unit]
Description=USB to Audio Output Routing
After=usb-gadget-audio.service sound.target
Requires=usb-gadget-audio.service

[Service]
Type=simple
ExecStart=/usr/local/bin/usb-audio-routing.sh
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
    echo "✅ Service file created"
fi

echo
echo "3. Reloading systemd and enabling service:"
sudo systemctl daemon-reload

if sudo systemctl enable usb-audio-routing.service; then
    echo "✅ Service enabled"
else
    echo "❌ Failed to enable service"
    exit 1
fi

echo
echo "4. Starting service:"
if sudo systemctl start usb-audio-routing.service; then
    echo "✅ Service started"
else
    echo "❌ Failed to start service"
    echo "Checking logs:"
    journalctl -u usb-audio-routing.service -n 10 --no-pager
fi

echo
echo "5. Final status check:"
systemctl status usb-audio-routing.service --no-pager -l

echo
echo "6. Is service enabled for boot?"
if systemctl is-enabled usb-audio-routing.service >/dev/null 2>&1; then
    echo "✅ Service is enabled for boot"
else
    echo "❌ Service is NOT enabled for boot"
fi

echo
echo "7. Check if alsaloop is running:"
if pgrep alsaloop >/dev/null; then
    echo "✅ alsaloop is running (PID: $(pgrep alsaloop))"
    ps aux | grep alsaloop | grep -v grep
else
    echo "❌ alsaloop is not running"
    echo "Manual start: ./start-routing.sh"
fi
