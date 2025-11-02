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

# Create log file
LOG_FILE="$HOME/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"
echo "Installation started at $(date)" > "$LOG_FILE"

# Display banner
clear
echo -e "${BLUE}     ._.   ________               __                   ._.     
echo -e "${BLUE} /\  | |  /  _____/  ____  __ ___/  |______    _____   | |  /\ 
echo -e "${BLUE} \/  |_| /   \  ___ /  _ \|  |  \   __\__  \  /     \  |_|  \/ 
echo -e "${BLUE} /\  |-| \    \_\  (  <_> )  |  /|  |  / __ \|  Y Y  \ |-|  /\ 
echo -e "${BLUE} \/  | |  \______  /\____/|____/ |__| (____  /__|_|  / | |  \/ 
echo -e "${BLUE}     |_|         \/                        \/      \/  |_|     

echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}  Arch Linux Hyprland Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo
echo "This installer will help you set up a complete"
echo "Hyprland environment with QuickShell."
echo
echo -e "${YELLOW}Installation log: $LOG_FILE${NC}"
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
echo "1) Fresh Minimal Install"
echo "   └─ No desktop environment, install Hyprland + dependencies only"
echo
echo "2) Complete Desktop Environment"
echo "   └─ Install GNOME first, then Hyprland configuration"
echo
echo "3) Hybrid Setup (Existing GNOME)"
echo "   └─ Keep GNOME, add Hyprland alongside"
echo
echo "4) Install Packages Only"
echo "   └─ Install all required packages without copying configs"
echo
echo "5) Apply Configurations Only"
echo "   └─ Copy dotfiles to system (packages must be installed)"
echo
echo "6) Full Automated Installation"
echo "   └─ Recommended for new systems - installs everything"
echo
echo "7) Exit"
echo
read -rp "Select an option [1-7]: " choice

case "$choice" in
  1)
    echo -e "${GREEN}==> Fresh Minimal Install selected${NC}"
    echo "Installation Type: Fresh Minimal Install" >> "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/install_base_deps.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/install_packages.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/user_setup.sh" 2>&1 | tee -a "$LOG_FILE"
    ;;
  2)
    echo -e "${GREEN}==> Complete Desktop Environment selected${NC}"
    echo "Installation Type: GNOME + Hyprland" >> "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/install_gnome.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/install_packages.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/user_setup.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/cleanup_gnome.sh" 2>&1 | tee -a "$LOG_FILE"
    ;;
  3)
    echo -e "${GREEN}==> Hybrid Setup selected${NC}"
    echo "Installation Type: Hybrid (GNOME + Hyprland)" >> "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/install_packages.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/user_setup.sh" 2>&1 | tee -a "$LOG_FILE"
    read -rp "Remove GNOME default apps? (y/N): " remove_gnome
    if [[ "$remove_gnome" =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/scripts/cleanup_gnome.sh" 2>&1 | tee -a "$LOG_FILE"
    fi
    ;;
  4)
    echo -e "${GREEN}==> Installing packages only${NC}"
    echo "Installation Type: Packages Only" >> "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/install_base_deps.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/install_packages.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh" 2>&1 | tee -a "$LOG_FILE"
    ;;
  5)
    echo -e "${GREEN}==> Applying configurations only${NC}"
    echo "Installation Type: Configs Only" >> "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/user_setup.sh" 2>&1 | tee -a "$LOG_FILE"
    ;;
  6)
    echo -e "${GREEN}==> Full Automated Installation${NC}"
    echo "Installation Type: Full Automated" >> "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/install_base_deps.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/install_packages.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh" 2>&1 | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/scripts/user_setup.sh" 2>&1 | tee -a "$LOG_FILE"
    ;;
  *)
    echo "Exiting."
    exit 0
    ;;
esac

echo
echo "Installation completed at $(date)" >> "$LOG_FILE"
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo
echo "Next steps:"
echo "1. Reboot your system"
echo "2. Select Hyprland from your login manager"
echo "3. Enjoy your new setup!"
echo
echo -e "${BLUE}Installation log saved to: ${YELLOW}$LOG_FILE${NC}"
echo
