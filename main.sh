#!/usr/bin/env bash
# ===========================
#  Arch Linux Setup Assistant
#  Universal Hyprland Config
# ===========================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color definitions
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

# Display banner
clear
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}  Arch Linux Hyprland Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo
echo "This installer will help you set up a complete"
echo "Hyprland environment with QuickShell."
echo

# Check if GNOME is installed
GNOME_INSTALLED=false
if pacman -Q gnome-shell &>/dev/null || pacman -Q gnome-desktop &>/dev/null; then
    GNOME_INSTALLED=true
    echo -e "${YELLOW}⚠ GNOME installation detected${NC}"
fi

echo
echo "======================================="
echo "  Installation Options"
echo "======================================="
echo
echo "1) Fresh install (no DE, install dependencies only)"
echo "2) Install GNOME first, then setup Hyprland config"
echo "3) Use existing GNOME, setup Hyprland config"
echo "4) Install packages and dependencies only"
echo "5) Setup user configs only"
echo "6) Full automated install (recommended for fresh systems)"
echo "7) Exit"
echo
read -rp "Select an option [1-7]: " choice

case "$choice" in
  1)
    echo -e "${GREEN}==> Fresh install selected${NC}"
    bash "$SCRIPT_DIR/scripts/install_base_deps.sh"
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    ;;
  2)
    echo -e "${GREEN}==> Installing GNOME first${NC}"
    bash "$SCRIPT_DIR/scripts/install_gnome.sh"
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    bash "$SCRIPT_DIR/scripts/cleanup_gnome.sh"
    ;;
  3)
    echo -e "${GREEN}==> Using existing GNOME${NC}"
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    read -rp "Remove GNOME default apps? (y/n): " remove_gnome
    if [[ "$remove_gnome" =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/scripts/cleanup_gnome.sh"
    fi
    ;;
  4)
    echo -e "${GREEN}==> Installing packages only${NC}"
    bash "$SCRIPT_DIR/scripts/install_base_deps.sh"
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    ;;
  5)
    echo -e "${GREEN}==> Setting up user configs only${NC}"
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    ;;
  6)
    echo -e "${GREEN}==> Full automated install${NC}"
    bash "$SCRIPT_DIR/scripts/install_base_deps.sh"
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    ;;
  *)
    echo "Exiting."
    exit 0
    ;;
esac

echo
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo
echo "Next steps:"
echo "1. Reboot your system"
echo "2. Select Hyprland from your login manager"
echo "3. Enjoy your new setup!"
echo
