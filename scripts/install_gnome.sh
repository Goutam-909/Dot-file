#!/usr/bin/env bash
# ===============================================
#  GNOME Installation Script
# ===============================================

set -e

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

install_if_missing() {
    local pkg="$1"
    if ! pacman -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}Installing $pkg...${NC}"
        sudo pacman -S --noconfirm --needed "$pkg"
    else
        echo -e "${YELLOW}✓ $pkg already installed${NC}"
    fi
}

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Installing GNOME Desktop${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

# Update system
echo -e "${GREEN}==> Updating system...${NC}"
sudo pacman -Syu --noconfirm

# Install GNOME
echo -e "${GREEN}==> Installing GNOME...${NC}"

GNOME_PKGS=(
    gnome
    gnome-extra
)

for pkg in "${GNOME_PKGS[@]}"; do
    install_if_missing "$pkg"
done

# Enable GDM
echo -e "${GREEN}==> Enabling GDM display manager...${NC}"
sudo systemctl enable gdm.service

# Enable NetworkManager
sudo systemctl enable NetworkManager.service

echo -e "${GREEN}✅ GNOME installation complete!${NC}"
echo -e "${YELLOW}⚠ GDM will start on next boot${NC}"
