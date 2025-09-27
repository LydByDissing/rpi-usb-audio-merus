# Raspberry Pi Zero USB Audio Device

Transform your Raspberry Pi Zero W into a professional USB audio device with automatic routing to external amplifiers and DACs.

## 🎵 What This Project Does

This project configures a Raspberry Pi Zero W as a **USB Audio Class 2 (UAC2) device** that appears to any host computer as a standard USB audio interface. Audio received via USB is automatically routed to connected audio hardware like DACs, amplifiers, or HATs.

### Key Features

- ✅ **USB Audio Class 2 compliance** - Works with any modern operating system
- ✅ **Automatic audio routing** - USB input → Physical audio output  
- ✅ **Professional audio quality** - 48kHz, stereo audio support
- ✅ **Zero-configuration** - Plug-and-play operation after setup
- ✅ **Survives reboots** - Automatic startup via systemd services
- ✅ **Supports various audio hardware** - HATs, USB DACs, I2S devices

## 🔧 Use Cases

- **USB to I2S converter** - Drive I2S DACs and amplifiers
- **Wireless audio bridge** - Add USB audio to devices without built-in support  
- **Audio development platform** - Test and prototype audio applications
- **Headless audio system** - Remote audio output via USB connection
- **Audio streaming endpoint** - Convert any USB-capable device to audio output

## 🏗️ Architecture

```
[Host Computer] ──USB──► [Pi Zero UAC2 Gadget] ──ALSA──► [Audio Hardware] ──► [Speakers]
```

The system creates:
1. **USB Composite Gadget** using Linux USB gadget framework
2. **UAC2 Audio Function** providing standard USB audio interface  
3. **ALSA Audio Routing** using `alsaloop` for real-time audio forwarding
4. **Systemd Services** ensuring automatic startup and reliability

## 🎯 Tested Hardware

### Raspberry Pi Models
- ✅ **Raspberry Pi Zero W** (primary target)
- ✅ **Raspberry Pi Zero 2 W** 
- ⚠️ **Raspberry Pi 4/5** (requires OTG USB port configuration)

### Audio Hardware  
- ✅ **Merus Audio HATs** (MA120x0P-based amplifiers)
- ✅ **HiFiBerry DAC/Amp HATs**
- ✅ **USB Audio interfaces** 
- ✅ **I2S DACs and amplifiers**
- ✅ **Built-in audio jack** (with quality limitations)

### Host Operating Systems
- ✅ **Linux** (PulseAudio, ALSA, PipeWire)
- ✅ **Windows 10/11** (native UAC2 support)  
- ✅ **macOS** (Core Audio)
- ✅ **Android** (USB OTG capable devices)

## 🚀 Quick Start

### Prerequisites

- Raspberry Pi Zero W with Raspberry Pi OS
- MicroSD card (8GB+)  
- **USB data cable** (not power-only) 
- Audio output hardware (HAT, USB DAC, or 3.5mm jack)

### Installation

1. **Clone this repository:**
   ```bash
   git clone https://github.com/yourusername/raspberry-pi-zero-as-usb-audio-device.git
   cd raspberry-pi-zero-as-usb-audio-device
   ```

2. **Run the installation script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   sudo reboot
   ```

3. **Connect via USB data port:**
   - Use the **center micro USB port** on Pi Zero (NOT the power port)
   - Connect to your host computer

4. **Verify operation:**
   ```bash
   # On Pi - check services
   systemctl status usb-gadget-audio.service
   systemctl status usb-audio-routing.service
   
   # On host - check device appears
   lsusb | grep -i audio
   aplay -l  # Linux
   ```

### Basic Usage

1. **On host computer:** Select "Pi Zero USB Audio" as audio output device
2. **Play audio** from any application  
3. **Hear output** through Pi's connected audio hardware

That's it! No additional configuration required.

## 📖 Documentation

- **[Installation Guide](docs/INSTALLATION.md)** - Detailed setup instructions
- **[Configuration](docs/CONFIGURATION.md)** - Advanced configuration options
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions  
- **[Hardware Compatibility](docs/HARDWARE.md)** - Tested devices and compatibility notes
- **[Development](docs/DEVELOPMENT.md)** - Contributing and development setup

## ⚡ Performance

- **Audio Latency:** ~10-50ms (depends on buffer configuration)
- **CPU Usage:** <5% on Pi Zero W during playback
- **Power Consumption:** +~50mA when active (USB bus powered)
- **Audio Quality:** 16-bit/48kHz stereo (transparent to source)

## 🛠️ Technical Details

### USB Gadget Configuration
- **Device Class:** Audio (0x01)
- **Protocol:** USB Audio Class 2 (UAC2)
- **Endpoints:** Isochronous audio streaming
- **Power:** Bus-powered (500mA max)

### Audio Pipeline  
- **Capture:** USB UAC2 gadget receives audio from host
- **Processing:** Real-time routing via ALSA `alsaloop`
- **Output:** Configurable audio hardware (I2S, USB, analog)

### System Services
- **`usb-gadget-audio.service`** - Configures USB audio gadget
- **`usb-audio-routing.service`** - Manages audio routing

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
git clone https://github.com/yourusername/raspberry-pi-zero-as-usb-audio-device.git
cd raspberry-pi-zero-as-usb-audio-device
./install.sh  # Test installation
```

## 📄 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

This ensures that any modifications or derivatives of this project must also be open source, protecting the community's investment in this work.

## 🙏 Acknowledgments

- **Linux USB Gadget Framework** - Foundation for USB device emulation
- **ALSA Project** - Audio routing and processing  
- **Raspberry Pi Foundation** - Hardware platform
- **Community contributors** - Testing, feedback, and improvements

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/raspberry-pi-zero-as-usb-audio-device/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/raspberry-pi-zero-as-usb-audio-device/discussions)
- **Wiki:** [Project Wiki](https://github.com/yourusername/raspberry-pi-zero-as-usb-audio-device/wiki)

---

⭐ **Star this repository** if you found it useful!
