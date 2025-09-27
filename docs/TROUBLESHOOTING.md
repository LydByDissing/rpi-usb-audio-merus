# Troubleshooting Guide

Common issues and solutions for the Raspberry Pi Zero USB Audio Device.

## Quick Diagnostics

Run the validation script to check your setup:
```bash
./validate-setup.sh
```

This will check services, audio devices, and basic functionality.

## Common Issues

### 1. USB Device Not Detected by Host

#### Symptoms
- `lsusb` doesn't show Pi Zero device
- No audio device in host sound settings
- Host doesn't recognize device when connected

#### Solutions

**Check USB Connection:**
```bash
# On Pi - verify USB gadget is active
cat /sys/kernel/config/usb_gadget/pi_audio/UDC
# Should show: 20980000.usb (or similar, not empty)

# Check if gadget service is running
systemctl status usb-gadget-audio.service
```

**Verify Correct USB Port:**
- Use **center micro USB port** on Pi Zero (data port)
- **NOT the outer port** (power only)
- Cable must be data cable, not power-only

**Check Cable and Host Port:**
- Try different USB cable (some are power-only)
- Try different USB port on host
- USB 3.0 ports sometimes have compatibility issues - try USB 2.0

**Service Restart:**
```bash
sudo systemctl restart usb-gadget-audio.service
sleep 5
# Disconnect and reconnect USB cable
```

### 2. No Audio Output from Pi

#### Symptoms
- USB device detected by host
- Playing audio but no sound from Pi speakers
- Audio routing service appears to be running

#### Solutions

**Check Audio Hardware:**
```bash
# List all audio devices
aplay -l

# Test audio output directly
speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -c 2 -t wav -l 1
```

**Verify Audio Routing:**
```bash
# Check if alsaloop is running
pgrep alsaloop
ps aux | grep alsaloop

# Check routing service
systemctl status usb-audio-routing.service
journalctl -u usb-audio-routing.service -n 10
```

**Manual Audio Routing Test:**
```bash
# Stop service and test manually
sudo systemctl stop usb-audio-routing.service
sudo pkill alsaloop

# Start manual routing
./start-routing.sh

# Play audio from host and check if it works
```

**Volume and Mixer Settings:**
```bash
# Check if audio is muted
alsamixer
# Navigate to your audio device and ensure it's not muted

# Or use amixer to check/set volume
amixer sget Master
amixer sset Master 80%
```

### 3. Service Start Failures

#### Symptoms
- Services show "failed" status
- Audio routing keeps restarting
- Installation completes but services don't start

#### Solutions

**Check Service Logs:**
```bash
# Detailed service logs
journalctl -u usb-gadget-audio.service -f
journalctl -u usb-audio-routing.service -f

# Recent errors
journalctl -u usb-gadget-audio.service --since "10 minutes ago"
```

**Common Service Issues:**

**USB Gadget Service Fails:**
```bash
# Check if dwc2 overlay is loaded
lsmod | grep dwc2

# Verify config.txt has the overlay
grep dwc2 /boot/config.txt

# If missing, add it and reboot
echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
sudo reboot
```

**Audio Routing Service Keeps Restarting:**
```bash
# Check audio device availability
aplay -l | grep -E "(UAC2|sndrpimerusamp)"

# Test alsaloop command manually
alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000
```

### 4. Audio Quality Issues

#### Symptoms
- Audio plays but with dropouts, crackling, or distortion
- Intermittent audio cutting out
- Poor audio quality

#### Solutions

**Buffer Size Adjustment:**
```bash
# Edit the routing service
sudo systemctl edit usb-audio-routing.service

# Add override:
[Service]
ExecStart=
ExecStart=/usr/bin/alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 100000 -r 48000

sudo systemctl daemon-reload
sudo systemctl restart usb-audio-routing.service
```

**USB Power Issues:**
- Ensure adequate power supply (2.5A recommended)
- Try powered USB hub if connecting multiple devices
- Check for voltage drops: `vcgencmd measure_volts`

**Sample Rate Mismatch:**
```bash
# Check what sample rates your audio hardware supports
cat /proc/asound/card1/pcm0p/info

# Match the alsaloop rate to your hardware capabilities
```

### 5. Host-Side Issues

#### Linux Host Issues

**PulseAudio Not Detecting Device:**
```bash
# Restart PulseAudio
pulseaudio -k
pulseaudio --start

# Check PulseAudio sinks
pactl list short sinks | grep -i usb

# Set as default sink
pactl set-default-sink alsa_output.usb-*Pi_Zero*
```

**ALSA Permissions:**
```bash
# Add user to audio group
sudo usermod -a -G audio $USER
# Log out and back in
```

#### Windows Host Issues

**Driver Issues:**
- Windows 10/11 should recognize UAC2 automatically
- If not detected, check Device Manager for unknown devices
- Try different USB port (avoid USB 3.0 if problematic)

**Audio Not Playing:**
- Check Windows Sound settings
- Set Pi Zero as default playback device
- Test with Windows sounds or media player

#### macOS Host Issues

**Audio MIDI Setup:**
- Open Audio MIDI Setup app
- Check if Pi Zero device appears
- Verify sample rate settings match (48kHz)

### 6. Performance Issues

#### High CPU Usage
```bash
# Check system load
top
htop

# Monitor alsaloop specifically
top -p $(pgrep alsaloop)

# Reduce CPU usage with larger buffers
# Edit routing service to use -t 100000 instead of -t 50000
```

#### Memory Issues
```bash
# Check memory usage
free -h

# Check for memory leaks
sudo systemctl restart usb-audio-routing.service
```

## Advanced Debugging

### Enable Debug Logging
```bash
# Add debug output to routing service
sudo systemctl edit usb-audio-routing.service

# Add:
[Service]
Environment=ALSA_DEBUG=1
ExecStart=
ExecStart=/usr/bin/alsaloop -C plughw:2,0 -P plughw:CARD=sndrpimerusamp,DEV=0 -t 50000 -r 48000 -v

sudo systemctl daemon-reload
sudo systemctl restart usb-audio-routing.service
```

### USB Gadget Debugging
```bash
# Check USB gadget configuration
ls -la /sys/kernel/config/usb_gadget/pi_audio/

# Monitor USB events
sudo dmesg | grep -i usb | tail -20

# Check UDC status
cat /sys/kernel/config/usb_gadget/pi_audio/UDC
```

### Audio System Debugging
```bash
# Check ALSA card details
cat /proc/asound/cards

# Check device capabilities
cat /proc/asound/card2/pcm0c/info  # UAC2 capture
cat /proc/asound/card1/pcm0p/info  # Audio output

# Monitor ALSA errors
journalctl -f | grep -i alsa
```

## Hardware-Specific Issues

### Different Pi Models

**Pi 4/5 OTG Configuration:**
```bash
# Add to /boot/config.txt
dtoverlay=dwc2,dr_mode=peripheral

# May need additional USB configuration
```

### Different Audio Hardware

**USB Audio Interfaces:**
```bash
# Find your USB audio device
aplay -l

# Update routing service for USB audio (usually card 1)
ExecStart=/usr/bin/alsaloop -C plughw:2,0 -P plughw:1,0 -t 50000 -r 48000
```

**HiFiBerry HATs:**
```bash
# Check HiFiBerry device name
aplay -l | grep -i hifiberry

# Update routing accordingly
ExecStart=/usr/bin/alsaloop -C plughw:2,0 -P plughw:CARD=sndrpihifiberry,DEV=0 -t 50000 -r 48000
```

## Getting Help

If you can't resolve the issue:

1. **Run validation script** and save output:
   ```bash
   ./validate-setup.sh > debug-output.txt 2>&1
   ```

2. **Collect service logs**:
   ```bash
   journalctl -u usb-gadget-audio.service -u usb-audio-routing.service --since "1 hour ago" > service-logs.txt
   ```

3. **System information**:
   ```bash
   cat /proc/cpuinfo | head -3 > system-info.txt
   aplay -l >> system-info.txt
   lsusb >> system-info.txt
   ```

4. **Create GitHub issue** with:
   - Description of the problem
   - Expected vs actual behavior  
   - Debug output and logs
   - Hardware setup details

## Complete Reset

If all else fails, completely reset the installation:

```bash
# Clean everything
./cleanup.sh
sudo reboot

# Fresh installation
./install.sh
sudo reboot

# Validate
./validate-setup.sh
```
