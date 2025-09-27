# Pi Zero USB Audio → Merus Amp Setup Guide

## Overview

This guide shows how to set up your Pi Zero as a USB audio device with automatic routing to a Merus amp. Audio routing is now **integrated into the main install.sh script** - no separate setup needed!

## Architecture

```
[Host Computer] → USB → [Pi Zero USB Audio Gadget] → ALSA routing → [Merus Amp] → Speakers
```

## Setup Steps

### 1. Complete Installation (on Pi Zero)

The main install script now handles everything:
```bash
chmod +x install.sh
./install.sh
sudo reboot
```

The install script automatically:
- ✅ Configures USB audio gadget  
- ✅ Sets up audio routing from USB to Merus amp
- ✅ Creates systemd services for both
- ✅ Enables automatic startup

### 2. Test from Host Computer

After Pi reboots, test the complete setup:
```bash
chmod +x test-audio-host.sh
./test-audio-host.sh
```

## Manual Setup (if scripts don't work)

### On Pi Zero:

1. **Find audio devices:**
   ```bash
   aplay -l
   ```

2. **Identify device cards:**
   - UAC2_Gadget: Usually card 1 (receives from host)
   - Merus amp: Usually card 0 (outputs to speakers)

3. **Start audio routing:**
   ```bash
   # Route from USB (card 1) to Merus amp (card 0)
   alsaloop -C hw:1,0 -P hw:0,0 -t 50000 -d &
   ```

### On Host:

1. **Find Pi Zero audio device:**
   ```bash
   aplay -l | grep -i "Pi Zero"
   ```

2. **Test audio:**
   ```bash
   # Replace X with the card number
   speaker-test -D plughw:X,0 -c 2 -t wav -l 1
   ```

## Making It Permanent

### Option 1: Add to Pi startup script
```bash
echo 'alsaloop -C hw:1,0 -P hw:0,0 -t 50000 -d &' >> ~/.bashrc
```

### Option 2: Create systemd service
```bash
sudo tee /etc/systemd/system/audio-routing.service << 'EOF'
[Unit]
Description=USB to Merus Audio Routing
After=sound.target usb-gadget-audio.service

[Service]
Type=simple
ExecStart=/usr/bin/alsaloop -C hw:1,0 -P hw:0,0 -t 50000
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable audio-routing.service
sudo systemctl start audio-routing.service
```

## Troubleshooting

### No sound from Merus amp:
1. Check audio devices: `aplay -l`
2. Test Merus directly: `speaker-test -D plughw:0,0`
3. Check ALSA mixer: `alsamixer`
4. Verify routing is running: `pgrep alsaloop`

### No audio from host:
1. Check if Pi appears in host audio: `aplay -l`
2. Check USB connection: `lsusb`
3. Try different audio applications

### Audio quality issues:
1. Adjust buffer size: `-t 100000` (larger buffer)
2. Try different sample rates in USB gadget config
3. Check for USB power issues

## Commands Quick Reference

**Pi Zero:**
```bash
# Check devices
aplay -l

# Start routing manually
alsaloop -C hw:1,0 -P hw:0,0 -t 50000 -d &

# Stop routing
pkill alsaloop

# Check if running
pgrep alsaloop
```

**Host:**
```bash
# Check Pi Zero device
aplay -l | grep -i "Pi Zero"

# Test audio (replace X with card number)
speaker-test -D plughw:X,0 -c 2 -t wav

# Play audio file
aplay -D plughw:X,0 your_file.wav
```

## Next Steps

Once audio routing is working:
1. Test with different audio sources (music, videos, etc.)
2. Optimize buffer sizes for your use case
3. Consider adding volume control
4. Set up automatic startup
