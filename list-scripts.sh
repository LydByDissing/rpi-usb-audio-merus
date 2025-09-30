#!/bin/bash
# Script Overview - List all available scripts with their purposes
#
# PURPOSE:
#   Provides a quick overview of all available scripts in the project
#   with their purposes and basic usage information.
#
# USAGE:
#   ./list-scripts.sh
#
# Copyright (C) 2024 Raspberry Pi Zero USB Audio Device Project Contributors
# Licensed under GPL v3 - see LICENSE file for details

echo "=== Raspberry Pi Zero USB Audio Device Scripts ==="
echo "Copyright (C) 2024 - Licensed under GPL v3"
echo

echo "📋 Available Scripts:"
echo

# Main installation and setup
echo "🚀 INSTALLATION & SETUP:"
echo "   ./install.sh              - Main installation script (sets up everything)"
echo "   ./cleanup.sh              - Complete removal and cleanup"
echo "   ./validate-setup.sh       - Validate installation and configuration"
echo

# Configuration management
echo "⚙️  CONFIGURATION MANAGEMENT:"
echo "   ./reload-config.sh        - Reload CamillaDSP configuration (SIGHUP/restart)"
echo "   ./watch-config.sh         - Auto-reload config when file changes"
echo "   ./test-reload.sh          - Test and verify reload functionality"
echo

# Debugging and diagnostics
echo "🔧 DEBUGGING & DIAGNOSTICS:"
echo "   ./debug-camilladsp.sh     - Comprehensive CamillaDSP diagnostics"
echo "   ./verify-routing.sh       - Verify audio routing through CamillaDSP"
echo "   ./start-routing.sh        - Manual CamillaDSP startup for testing"
echo

# Getting help
echo "❓ GETTING HELP:"
echo "   Most scripts support --help or -h for detailed usage information"
echo "   Example: ./install.sh --help"
echo

# Workflow guidance
echo "📖 TYPICAL WORKFLOW:"
echo "   1. ./install.sh           # Install and set up everything"
echo "   2. nano camilladsp.yml    # Edit your audio processing configuration"
echo "   3. ./reload-config.sh     # Apply configuration changes"
echo "   4. ./validate-setup.sh    # Verify everything is working"
echo "   5. ./debug-camilladsp.sh  # Troubleshoot any issues"
echo

echo "For detailed help on any script, run: ./script-name.sh --help"
echo "Documentation: README.md"
