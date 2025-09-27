# Contributing to Raspberry Pi Zero USB Audio Device

Thank you for your interest in contributing to this project! This guide will help you get started.

## Code of Conduct

This project follows a simple code of conduct:
- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and improve
- Credit others for their contributions

## How to Contribute

### Reporting Issues

Before creating a new issue:
1. **Search existing issues** to avoid duplicates
2. **Run the validation script**: `./validate-setup.sh`
3. **Collect debug information** (see template below)

**Issue Template:**
```markdown
## Problem Description
Brief description of the issue

## Expected Behavior
What should happen

## Actual Behavior  
What actually happens

## Environment
- Pi Model: (Pi Zero W, Pi Zero 2W, etc.)
- OS Version: (output of `cat /etc/os-release`)
- Audio Hardware: (HAT model, USB device, etc.)
- Host OS: (Linux, Windows, macOS)

## Debug Information
```
./validate-setup.sh
```

## Logs
```
journalctl -u usb-gadget-audio.service -u usb-audio-routing.service --since "1 hour ago"
```

## Steps to Reproduce
1. 
2. 
3. 
```

### Suggesting Features

For feature requests:
1. **Check existing issues** for similar requests
2. **Explain the use case** - why is this feature needed?
3. **Describe the solution** - how should it work?
4. **Consider alternatives** - are there other ways to achieve this?

### Code Contributions

#### Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork**:
   ```bash
   git clone https://github.com/yourusername/raspberry-pi-zero-as-usb-audio-device.git
   cd raspberry-pi-zero-as-usb-audio-device
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Testing Your Changes

1. **Test on actual hardware** - simulation is not sufficient
2. **Run validation script**:
   ```bash
   ./validate-setup.sh
   ```
3. **Test installation from scratch**:
   ```bash
   ./cleanup.sh
   ./install.sh
   sudo reboot
   ./validate-setup.sh
   ```
4. **Test with different hardware** if possible

#### Code Style

**Shell Scripts:**
- Use `#!/bin/bash` shebang
- Include GPL v3 license header
- Use descriptive variable names
- Add comments for complex logic
- Use `set -e` for error handling
- Quote variables: `"$VAR"` not `$VAR`

**Example:**
```bash
#!/bin/bash
# Description of what this script does
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

set -e

GADGET_DIR="/sys/kernel/config/usb_gadget/pi_audio"

echo "Starting configuration..."
if [ -d "$GADGET_DIR" ]; then
    echo "✓ Gadget directory exists"
else
    echo "❌ Gadget directory not found"
    exit 1
fi
```

**Documentation:**
- Use Markdown format
- Include code examples with syntax highlighting
- Add troubleshooting sections
- Keep line length reasonable (~80 chars)
- Use clear headings and structure

#### Commit Guidelines

**Commit Message Format:**
```
category: brief description

More detailed explanation if needed. Explain what changed
and why, not just what was done.

Fixes #123
```

**Categories:**
- `install`: Installation script changes
- `service`: Systemd service modifications  
- `audio`: Audio routing improvements
- `docs`: Documentation updates
- `fix`: Bug fixes
- `feature`: New functionality
- `test`: Testing improvements

**Examples:**
```
install: add support for different audio hardware

Update installation script to auto-detect audio devices
and configure routing appropriately. Supports HiFiBerry,
USB audio, and generic ALSA devices.

Fixes #45

docs: improve troubleshooting guide

Add section for audio quality issues and buffer tuning.
Include steps for different host operating systems.

service: reduce audio latency with smaller buffers

Change default buffer size from 50000 to 25000 for
lower latency. May cause dropouts on some hardware.
```

#### Pull Request Process

1. **Update documentation** if needed
2. **Add/update tests** for new functionality
3. **Ensure all scripts are executable**
4. **Test on clean installation**
5. **Create pull request** with clear description

**Pull Request Template:**
```markdown
## Changes
- Brief list of changes made
- Link to any related issues

## Testing
- [ ] Tested on Pi Zero W
- [ ] Tested clean installation
- [ ] Validated with ./validate-setup.sh
- [ ] Documentation updated

## Compatibility
- [ ] Backwards compatible
- [ ] No breaking changes
- OR: Breaking changes documented with migration guide
```

### Documentation Contributions

Documentation improvements are always welcome:

**Areas needing help:**
- Hardware compatibility testing
- Host OS specific guides
- Advanced configuration examples
- Video tutorials
- Translation to other languages

**Documentation Standards:**
- Clear, step-by-step instructions
- Include expected output examples
- Add troubleshooting for common issues
- Test all instructions on actual hardware

## Development Areas

### Priority Areas

1. **Hardware Compatibility**
   - Test with different Pi models
   - Support for various audio HATs
   - USB audio interface compatibility
   - Host OS compatibility testing

2. **Audio Quality**
   - Latency optimization
   - Sample rate/bit depth options
   - Buffer size auto-tuning
   - Audio format negotiation

3. **Ease of Use**
   - Better error messages
   - Automatic hardware detection
   - Web-based configuration interface
   - Installation wizard

4. **Advanced Features**
   - Multiple audio endpoints
   - MIDI support
   - Audio effects processing
   - Volume control integration

### Technical Debt

- Improve error handling in scripts
- Add comprehensive unit tests
- Modularize installation script
- Create Python-based configuration tool

## Release Process

### Version Numbering

This project uses semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

### Release Checklist

For maintainers preparing releases:

1. **Test on multiple hardware configurations**
2. **Update version numbers** in relevant files
3. **Update CHANGELOG.md**
4. **Create release notes** with:
   - New features
   - Bug fixes
   - Breaking changes
   - Known issues
5. **Tag release** in Git
6. **Update documentation** if needed

## Getting Help

### For Contributors

- **GitHub Discussions** - General questions about contributing
- **GitHub Issues** - Bug reports and feature requests
- **Code Review** - Pull request feedback and suggestions

### For Users

- **Documentation** - Check docs/ directory first
- **Troubleshooting Guide** - Common issues and solutions
- **GitHub Issues** - Report bugs or request features
- **Validation Script** - `./validate-setup.sh` for diagnostics

## Recognition

Contributors will be:
- Listed in project acknowledgments
- Credited in release notes for significant contributions
- Added to CONTRIBUTORS.md file

Thank you for helping make this project better for everyone!
