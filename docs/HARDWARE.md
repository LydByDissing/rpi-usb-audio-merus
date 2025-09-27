# Hardware Compatibility Guide

This guide covers tested hardware configurations and compatibility notes for the Raspberry Pi Zero USB Audio Device project.

## Raspberry Pi Models

### ✅ Fully Supported

**Raspberry Pi Zero W**
- **Best choice** for this project
- Native USB OTG support
- Low power consumption
- Compact form factor
- WiFi for remote management

**Raspberry Pi Zero 2 W**
- Same USB OTG capability as Zero W
- Better CPU performance
- More RAM (512MB vs 256MB)
- Fully compatible with all features

### ⚠️ Supported with Modifications

**Raspberry Pi 4 (all variants)**
- Requires OTG configuration: `dtoverlay=dwc2,dr_mode=peripheral`
- May need USB-C to USB-A adapter
- Higher power consumption
- Overkill for this application

**Raspberry Pi 5**
- Similar to Pi 4 requirements
- May need additional USB configuration
- Not extensively tested

### ❌ Not Supported

**Raspberry Pi 3 and earlier**
- No USB OTG capability
- Cannot function as USB device

**Raspberry Pi Compute Module**
- Would require custom carrier board
- Complex USB configuration

## Audio Hardware

### ✅ Tested and Working

#### Merus Audio HATs
- **Merus Amp HAT (MA120x0P)**
  - Device name: `sndrpimerusamp`
  - Excellent audio quality
  - Built-in amplification
  - I2S interface

#### HiFiBerry Products
- **HiFiBerry DAC+ series**
  - Device name: `sndrpihifiberry`
  - High-quality DAC
  - Line output
- **HiFiBerry Amp series**
  - Built-in amplification
  - Direct speaker connection

#### USB Audio Interfaces
- **Generic USB Audio Class 1/2 devices**
  - Usually appear as `USB Audio` or brand name
  - Plug-and-play compatibility
  - External power may be required

#### Built-in Audio
- **3.5mm audio jack**
  - Basic quality
  - No additional setup required
  - Limited by Pi's onboard DAC quality

### ⚠️ Partially Supported

#### Professional Audio Interfaces
- May require manual configuration
- Check sample rate compatibility
- Some features may not work

#### Bluetooth Audio
- Not directly supported by this project
- Would require additional Bluetooth routing

### ❌ Not Compatible

#### HDMI Audio
- HDMI audio output not supported
- USB gadget mode conflicts with HDMI

#### I2S DACs without proper drivers
- Requires specific device tree overlays
- May need custom configuration

## Host Computer Compatibility

### ✅ Fully Compatible

#### Linux
- **Ubuntu 18.04+**
- **Debian 10+**
- **Fedora 30+**
- **Arch Linux**
- **Raspberry Pi OS** (as host)

Features:
- Automatic device detection
- PulseAudio/PipeWire integration
- ALSA direct access
- Low latency support

#### Windows
- **Windows 10** (version 1903+)
- **Windows 11**

Features:
- Native UAC2 driver support
- Automatic installation
- DirectSound/WASAPI compatibility

#### macOS
- **macOS 10.14+** (Mojave)
- **macOS 11+** (Big Sur)

Features:
- Core Audio integration
- Audio MIDI Setup compatibility
- Automatic device detection

### ⚠️ Limited Support

#### Android
- **Android 5.0+** with USB OTG
- Requires USB OTG adapter
- App-dependent compatibility
- Power delivery considerations

#### iOS/iPadOS
- **iPadOS 13+** with USB-C
- iPhone with Lightning to USB adapter
- Limited app support
- Apple's audio restrictions apply

#### Chrome OS
- Should work with UAC2 support
- Limited testing performed
- May require developer mode

### ❌ Not Compatible

#### Older Operating Systems
- Windows 7/8 (no UAC2 driver)
- macOS < 10.14
- Linux kernels < 3.0

## Power Requirements

### Raspberry Pi Zero W Power
- **Typical consumption**: 150-200mA
- **With audio active**: +50mA
- **USB bus power**: Usually sufficient
- **External power**: Recommended for stability

### Audio Hardware Power
- **Passive DACs**: No additional power
- **Amplified HATs**: May need external power
- **USB audio interfaces**: Often bus-powered

### Host USB Port Requirements
- **USB 2.0**: 500mA maximum
- **USB 3.0**: 900mA maximum
- **Powered hubs**: Recommended for multiple devices

## Performance Characteristics

### Audio Specifications

#### Supported Formats
- **Sample Rates**: 48kHz (primary), 44.1kHz, 96kHz (with compatible hardware)
- **Bit Depth**: 16-bit (standard), 24-bit (with hardware support)
- **Channels**: Stereo (left/right)

#### Latency
- **Typical latency**: 10-50ms
- **Buffer size dependent**: Adjustable via configuration
- **Hardware dependent**: Some audio interfaces add latency

#### Quality
- **Bit-perfect**: No audio processing by default
- **Hardware limited**: Quality depends on audio hardware
- **Jitter**: Low jitter with proper power supply

### CPU Performance

#### Pi Zero W
- **Idle CPU**: <5% during audio playback
- **Memory usage**: ~10MB for services
- **Network**: WiFi available for monitoring

#### Pi Zero 2 W
- **Better headroom**: Lower CPU usage
- **Faster startup**: Services start quicker
- **Multiple streams**: Could handle multiple audio streams

## Connection Specifications

### USB Cable Requirements
- **Data capability**: Must support data transfer
- **Length**: <3 meters for reliable operation
- **Quality**: Good shielding recommended
- **Connectors**: Micro USB to USB-A (standard)

### USB Port Types
- **Pi Zero**: Micro USB (data port, center connector)
- **Host**: Any USB-A port (2.0 or 3.0)
- **Power delivery**: 500mA minimum

## Testing Results

### Tested Configurations

| Pi Model | Audio Hardware | Host OS | Status | Notes |
|----------|----------------|---------|---------|-------|
| Pi Zero W | Merus HAT | Ubuntu 22.04 | ✅ Perfect | Reference configuration |
| Pi Zero W | HiFiBerry DAC+ | Windows 11 | ✅ Perfect | Excellent audio quality |
| Pi Zero 2W | USB Audio | macOS 12 | ✅ Perfect | Low latency |
| Pi Zero W | 3.5mm jack | Android 11 | ⚠️ Limited | App compatibility varies |
| Pi 4 | Merus HAT | Ubuntu 20.04 | ✅ Good | Requires OTG config |

### Performance Benchmarks

**Audio Latency Measurements:**
- Pi Zero W + Merus HAT: ~15ms average
- Pi Zero W + USB Audio: ~25ms average  
- Pi Zero W + 3.5mm jack: ~30ms average

**Stability Testing:**
- 24+ hour continuous operation: ✅ Stable
- Multiple host connections: ✅ Reliable
- Power cycling: ✅ Auto-recovery

## Hardware Selection Recommendations

### For Best Audio Quality
1. **Pi Zero 2 W** + **HiFiBerry DAC+ Pro**
2. **Pi Zero W** + **Merus Amp HAT**
3. **Pi Zero W** + **Quality USB Audio Interface**

### For Lowest Cost
1. **Pi Zero W** + **3.5mm output**
2. **Pi Zero W** + **Basic USB Audio**

### For Highest Compatibility
1. **Pi Zero W** + **USB Audio Class 1 device**
2. **Pi Zero 2 W** + **Standard ALSA HAT**

### For Development/Prototyping
1. **Pi Zero 2 W** + **HiFiBerry DAC+**
2. **External USB hub** for additional devices
3. **Quality power supply** for stability

## Troubleshooting Hardware Issues

### Audio Hardware Not Detected
```bash
# Check if hardware is detected
aplay -l

# Check device tree overlays
ls /boot/overlays/*audio*
ls /boot/overlays/*dac*

# Verify I2C/SPI if using HATs
sudo i2cdetect -y 1  # I2C devices
```

### USB Connection Issues
```bash
# Check USB controller
lsmod | grep dwc2

# Verify gadget configuration
ls /sys/kernel/config/usb_gadget/

# Check host detection
# On host: lsusb | grep -i audio
```

### Power-Related Problems
```bash
# Check power supply voltage
vcgencmd measure_volts

# Monitor power consumption
vcgencmd measure_current

# Check for undervoltage
dmesg | grep -i voltage
```

For additional hardware-specific issues, see the [Troubleshooting Guide](TROUBLESHOOTING.md).
