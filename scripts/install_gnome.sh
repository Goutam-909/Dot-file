#!/usr/bin/env bash
# ===============================================
#  GNOME Installation
# ===============================================

set -e

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Cleanup lock on interrupt
trap 'sudo rm -f /var/lib/pacman/db.lck 2>/dev/null; exit 130' INT TERM

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Installing GNOME${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

sudo pacman -Syu

if ! pacman -Q gnome &>/dev/null; then
    sudo pacman -S --needed gnome gnome-extra
fi

sudo systemctl enable gdm.service
sudo systemctl enable NetworkManager.service

echo -e "${GREEN}✅ GNOME installed!${NC}"
