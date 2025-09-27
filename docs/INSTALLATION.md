# Installation Guide

Complete installation guide for setting up your Raspberry Pi Zero as a USB audio device.

## Prerequisites

### Hardware Requirements

- **Raspberry Pi Zero W** (recommended) or Raspberry Pi Zero 2 W
- **MicroSD card** (8GB or larger, Class 10 recommended)
- **USB data cable** (NOT power-only) - usually the cable that comes with phones
- **Audio output hardware** - one of:
  - Audio HAT (HiFiBerry, Merus, etc.)
  - USB audio interface
  - 3.5mm audio jack (basic quality)
  - I2S DAC

### Software Requirements

- **Raspberry Pi OS** (latest version recommended)
- **SSH access** or direct terminal access to Pi
- **Internet connection** during installation

## Step-by-Step Installation

### 1. Prepare Raspberry Pi OS

1. **Flash Raspberry Pi OS** to SD card using Raspberry Pi Imager
2. **Enable SSH** (if using headless setup):
   ```bash
   # Create empty ssh file in boot partition
   touch /boot/ssh
   ```
3. **Configure WiFi** (if needed):
   ```bash
   # Create wpa_supplicant.conf in boot partition
   cat > /boot/wpa_supplicant.conf << EOF
   country=US
   ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
   update_config=1
   
   network={
       ssid="YourNetworkName"
       psk="YourPassword"
   }
   EOF
   ```

### 2. Initial Pi Setup

1. **Boot the Pi** and connect via SSH or direct terminal
2. **Update the system**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
3. **Install git** (if not already installed):
   ```bash
   sudo apt install git -y
   ```

### 3. Clone and Install

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/raspberry-pi-zero-as-usb-audio-device.git
   cd raspberry-pi-zero-as-usb-audio-device
   ```

2. **Run the installation script**:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **Reboot the Pi**:
   ```bash
   sudo reboot
   ```

### 4. Connect Hardware

1. **Wait for Pi to boot completely** (about 30-60 seconds)
2. **Connect USB cable**:
   - Use the **center micro USB port** on Pi Zero (DATA port)
   - Connect to your host computer
   - **Do NOT use the power port** (outer micro USB)

### 5. Verify Installation

1. **On the Pi**, check services:
   ```bash
   ./validate-setup.sh
   ```
   
   Or manually:
   ```bash
   systemctl status usb-gadget-audio.service
   systemctl status usb-audio-routing.service
   ```

2. **On the host**, check device detection:
   ```bash
   # Linux
   lsusb | grep -i audio
   aplay -l | grep -i "pi zero"
   
   # macOS
   system_profiler SPUSBDataType | grep -A 10 -i audio
   
   # Windows
   # Check Device Manager → Sound, video and game controllers
   # or Control Panel → Sound
   ```

## Troubleshooting Installation

### Common Issues

#### Services Not Starting
```bash
# Check service status
systemctl status usb-gadget-audio.service
systemctl status usb-audio-routing.service

# Check logs
journalctl -u usb-gadget-audio.service -n 20
journalctl -u usb-audio-routing.service -n 20

# Restart services
sudo systemctl restart usb-gadget-audio.service
sudo systemctl restart usb-audio-routing.service
```

#### USB Device Not Detected
1. **Verify USB cable** - must be data cable, not power-only
2. **Check correct port** - center micro USB on Pi Zero (not power port)
3. **Wait after boot** - services take 30-60 seconds to fully initialize
4. **Try different host port** - some USB ports have power limitations

#### Audio Not Working
1. **Check audio hardware**:
   ```bash
   aplay -l  # Should show your audio device
   ```
2. **Test audio output directly**:
   ```bash
   speaker-test -D plughw:CARD=sndrpimerusamp,DEV=0 -c 2
   ```
3. **Check audio routing**:
   ```bash
   pgrep alsaloop  # Should show a process ID
   ```

#### Boot Configuration Issues
If the Pi won't boot after installation:
1. **Remove SD card** and mount on another computer
2. **Edit /boot/config.txt** and remove the line: `dtoverlay=dwc2`
3. **Boot Pi normally** and retry installation

### Manual Recovery

If automatic installation fails, you can clean up and retry:

```bash
# Clean up previous installation
./cleanup.sh

# Retry installation
./install.sh
sudo reboot
```

### Hardware-Specific Notes

#### Pi Zero vs Pi Zero 2W
- Both work identically
- Pi Zero 2W has better performance but same USB OTG capability

#### Different Audio Hardware
The installation script is optimized for Merus audio HATs. For other hardware:

1. **Check your audio device**:
   ```bash
   aplay -l
   ```

2. **Update routing command** in `/etc/systemd/system/usb-audio-routing.service`:
   ```bash
   # Replace the ExecStart line with your audio device
   ExecStart=/usr/bin/alsaloop -C plughw:2,0 -P plughw:YOUR_CARD,0 -t 50000 -r 48000
   ```

3. **Restart service**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart usb-audio-routing.service
   ```

## Advanced Configuration

### Custom USB Device Description
Edit `/usr/local/bin/usb-gadget-audio.sh` and modify:
```bash
MANUFACTURER="Your Company Name"
PRODUCT="Your Audio Device Name"
```

### Audio Quality Settings
Modify the UAC2 configuration in the gadget script:
```bash
# Higher sample rates (if supported by hardware)
echo 96000 > c_srate
echo 96000 > p_srate

# Higher bit depth
echo 3 > c_ssize  # 24-bit
echo 3 > p_ssize  # 24-bit
```

### Buffer Tuning
Adjust audio latency vs stability in the routing service:
```bash
# Lower latency (may cause dropouts)
-t 25000

# Higher stability (more latency)
-t 100000
```

## Next Steps

After successful installation:
1. **Test basic functionality** - play audio from host
2. **Configure host audio settings** - set Pi as default device if desired
3. **Check audio quality** - verify no dropouts or distortion
4. **Read [Configuration Guide](CONFIGURATION.md)** for advanced options
5. **See [Troubleshooting Guide](TROUBLESHOOTING.md)** for common issues
