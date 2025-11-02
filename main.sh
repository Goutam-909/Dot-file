#!/usr/bin/env bash
# ===========================
#  Arch Linux Setup
# ===========================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'

clear
echo -e "${BLUE}     ._.   ________               __                   ._.     "
echo -e "${BLUE} /\  | |  /  _____/  ____  __ ___/  |______    _____   | |  /\ "
echo -e "${BLUE} \/  |_| /   \  ___ /  _ \|  |  \   __\__  \  /     \  |_|  \/ "
echo -e "${BLUE} /\  |-| \    \_\  (  <_> )  |  /|  |  / __ \|  Y Y  \ |-|  /\ "
echo -e "${BLUE} \/  | |  \______  /\____/|____/ |__| (____  /__|_|  / | |  \/ "
echo -e "${BLUE}     |_|         \/                        \/      \/  |_|     "

echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}  Arch Linux Hyprland Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo
echo "1) Fresh Minimal Install"
echo "   └─ Hyprland + dependencies only"
echo
echo "2) Complete Desktop Environment"
echo "   └─ GNOME + Hyprland"
echo
echo "3) Hybrid Setup"
echo "   └─ Keep existing GNOME, add Hyprland"
echo
echo "4) Install Packages Only"
echo
echo "5) Apply Configurations Only"
echo
echo "6) Full Automated"
echo
echo "7) Exit"
echo
read -rp "Select [1-7]: " choice

case "$choice" in
  1)
    bash "$SCRIPT_DIR/scripts/install_base_deps.sh"
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    ;;
  2)
    bash "$SCRIPT_DIR/scripts/install_gnome.sh"
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    bash "$SCRIPT_DIR/scripts/cleanup_gnome.sh"
    ;;
  3)
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    read -rp "Remove GNOME apps? (y/N): " remove_gnome
    [[ "$remove_gnome" =~ ^[Yy]$ ]] && bash "$SCRIPT_DIR/scripts/cleanup_gnome.sh"
    ;;
  4)
    bash "$SCRIPT_DIR/scripts/install_base_deps.sh"
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    ;;
  5)
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    ;;
  6)
    bash "$SCRIPT_DIR/scripts/install_base_deps.sh"
    bash "$SCRIPT_DIR/scripts/install_packages.sh"
    bash "$SCRIPT_DIR/scripts/setup_optional.sh"
    bash "$SCRIPT_DIR/scripts/user_setup.sh"
    ;;
  *)
    exit 0
    ;;
esac

echo
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo
