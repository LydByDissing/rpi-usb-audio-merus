# Raspberry Pi Zero USB Audio Device with CamillaDSP

Transform your Raspberry Pi Zero W into a professional USB audio device with integrated digital signal processing and automatic routing to external amplifiers and DACs.

## 🎵 What This Project Does

This project configures a Raspberry Pi Zero W as a **USB Audio Class 2 (UAC2) device** that appears to any host computer as a standard USB audio interface. Audio received via USB is processed through **CamillaDSP** for advanced signal processing, then routed to connected audio hardware like DACs, amplifiers, or HATs.

### Key Features

- ✅ **USB Audio Class 2 compliance** - Works with any modern operating system
- ✅ **CamillaDSP integration** - Advanced audio processing (EQ, crossover, room correction)
- ✅ **Real-time audio processing** - USB input → CamillaDSP → Physical audio output  
- ✅ **Professional audio quality** - 48kHz, stereo audio support with DSP capabilities
- ✅ **Web-based configuration** - Remote control via CamillaDSP API (port 1234)
- ✅ **Zero-configuration** - Plug-and-play operation after setup
- ✅ **Survives reboots** - Automatic startup via systemd services
- ✅ **Supports various audio hardware** - HATs, USB DACs, I2S devices

## 🔧 Use Cases

- **USB to I2S converter with DSP** - Drive I2S DACs and amplifiers with audio processing
- **Active crossover system** - Multi-way speaker systems with digital crossovers
- **Room correction system** - Apply equalization and room corrections
- **Wireless audio bridge** - Add USB audio to devices without built-in support  
- **Audio development platform** - Test and prototype audio applications with DSP
- **Headless audio system** - Remote audio output with web-based control
- **Audio streaming endpoint** - Convert any USB-capable device to processed audio output

## 🏗️ Architecture

```
[Host Computer] ──USB──► [Pi Zero UAC2 Gadget] ──► [CamillaDSP] ──► [Audio Hardware] ──► [Speakers]
                                                       │
                                               [Web API :1234]
```

The system creates:
1. **USB Composite Gadget** using Linux USB gadget framework
2. **UAC2 Audio Function** providing standard USB audio interface  
3. **CamillaDSP Processing** for real-time audio processing and routing
4. **Web API Interface** for remote configuration and control
5. **Systemd Services** ensuring automatic startup and reliability

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

   The installation script will automatically:
   - Download the latest CamillaDSP binary (v3.0.1) from GitHub
   - Skip download if correct version is already installed
   - Configure USB Audio Class 2 gadget
   - Set up systemd services for automatic startup
   - Install CamillaDSP configuration optimized for USB → Merus amp

   **Advanced options:**
   ```bash
   # Override CamillaDSP version
   CAMILLADSP_VERSION=v3.0.0 ./install.sh
   
   # Force re-download even if correct version exists
   ./install.sh --force-download
   
   # Show all available options
   ./install.sh --help
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
3. **Hear processed output** through Pi's connected audio hardware

### Advanced Usage

1. **Configure DSP:** Access CamillaDSP web interface at `http://[pi-ip]:1234`
2. **Modify processing:** Edit `/usr/local/etc/camilladsp.yml` for custom audio processing
3. **Monitor system:** Use debug scripts `./debug-camilladsp.sh` for troubleshooting

That's it! Audio processing starts automatically.

## 🎛️ CamillaDSP Configuration

The default configuration provides simple passthrough processing. You can customize it for advanced audio processing:

### Example DSP Features
- **Equalization:** Adjust frequency response
- **Crossover:** Multi-way speaker systems  
- **Room correction:** FIR/IIR filters for acoustic correction
- **Dynamic range:** Compression and limiting
- **Delay compensation:** Time alignment

### Configuration Files
- **Main config:** `/usr/local/etc/camilladsp.yml`
- **Web interface:** `http://[pi-ip]:1234` (when running)
- **Service logs:** `sudo journalctl -u camilladsp -f`

### Configuration Management

**Easy Workflow:**
1. **Install:** Run `./install.sh` (creates `camilladsp.yml` from template)
2. **Edit:** Modify `./camilladsp.yml` for your audio processing needs
3. **Apply:** Run `./reload-config.sh` to copy changes and reload
4. **Test:** Audio processing updates immediately

**Available Tools:**
- **Live reload:** `./reload-config.sh` (copies local config + SIGHUP reload)
- **Auto-reload:** `./watch-config.sh` (monitors `./camilladsp.yml` for changes)
- **Validate config:** `/usr/local/bin/camilladsp -c /usr/local/etc/camilladsp.yml`
- **Test workflow:** `./test-reload.sh` (shows current config status)
- **Manual methods:** Service restart or websocket API

**File Locations:**
- **Template:** `camilladsp.yml.template` (in git, don't edit directly)
- **Working config:** `./camilladsp.yml` (created from template, your edits)
- **Service reads:** `/usr/local/etc/camilladsp.yml` (system location)

### Customization

**Quick Start:**
```bash
# Edit your audio processing settings
nano camilladsp.yml

# Apply changes instantly
./reload-config.sh

# Or watch for changes automatically
./watch-config.sh
```

**Configuration Options:**
CamillaDSP supports extensive audio processing capabilities:
- **Equalization:** Biquad filters, parametric EQ, graphic EQ
- **Crossover filters:** For multi-way speaker systems
- **Room correction:** FIR/IIR filters from measurement data
- **Dynamic processing:** Compressors, limiters, AGC
- **Delay compensation:** Per-channel delays for time alignment
- **Convolution:** Impulse response processing for room correction

See the [CamillaDSP documentation](https://github.com/HEnquist/camilladsp) for detailed configuration options and examples.

## 📖 Documentation

- **[Installation Guide](docs/INSTALLATION.md)** - Detailed setup instructions
- **[Configuration](docs/CONFIGURATION.md)** - Advanced configuration options
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions  
- **[Hardware Compatibility](docs/HARDWARE.md)** - Tested devices and compatibility notes
- **[Development](docs/DEVELOPMENT.md)** - Contributing and development setup

## ⚡ Performance

- **Audio Latency:** ~20-100ms (depends on CamillaDSP buffer configuration)
- **CPU Usage:** <15% on Pi Zero W during playback with DSP processing
- **Power Consumption:** +~100mA when active (USB bus powered)
- **Audio Quality:** 16-bit/48kHz stereo input, 32-bit processing, configurable output
- **DSP Capabilities:** Real-time EQ, crossover, convolution, and more

## 🛠️ Technical Details

### USB Gadget Configuration
- **Device Class:** Audio (0x01)
- **Protocol:** USB Audio Class 2 (UAC2)
- **Endpoints:** Isochronous audio streaming
- **Power:** Bus-powered (500mA max)

### Audio Pipeline  
- **Capture:** USB UAC2 gadget receives audio from host
- **Processing:** Real-time processing via CamillaDSP (EQ, crossover, etc.)
- **Output:** Configurable audio hardware (I2S, USB, analog)

### System Services
- **`usb-gadget-audio.service`** - Configures USB audio gadget
- **`camilladsp.service`** - Manages CamillaDSP audio processing and routing

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
- **CamillaDSP Documentation:** [CamillaDSP Project](https://github.com/HEnquist/camilladsp)

---

⭐ **Star this repository** if you found it useful!
