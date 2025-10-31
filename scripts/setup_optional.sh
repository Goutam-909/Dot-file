#!/usr/bin/env bash
# ===============================================
#  Optional Components Setup
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; BLUE='\033[1;34m'; NC='\033[0m'

install_if_missing() {
    local pkg="$1"
    if ! pacman -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}Installing $pkg...${NC}"
        sudo pacman -S --noconfirm --needed "$pkg"
    else
        echo -e "${YELLOW}✓ $pkg already installed${NC}"
    fi
}

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Optional Components Setup${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# NVIDIA drivers
read -rp "Do you have an NVIDIA GPU? Install NVIDIA drivers? (y/n): " install_nvidia
if [[ "$install_nvidia" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing NVIDIA drivers...${NC}"
    
    # Detect GPU
    if lspci | grep -i nvidia &>/dev/null; then
        install_if_missing nvidia
        install_if_missing nvidia-utils
        install_if_missing nvidia-settings
        
        # Check for laptop (optimus)
        if [[ -f /sys/class/dmi/id/chassis_type ]]; then
            chassis_type=$(cat /sys/class/dmi/id/chassis_type)
            # 8=Portable, 9=Laptop, 10=Notebook
            if [[ "$chassis_type" == "8" || "$chassis_type" == "9" || "$chassis_type" == "10" ]]; then
                echo -e "${YELLOW}Laptop detected. Consider installing nvidia-prime for Optimus support.${NC}"
                read -rp "Install nvidia-prime? (y/n): " install_prime
                if [[ "$install_prime" =~ ^[Yy]$ ]]; then
                    install_if_missing nvidia-prime
                fi
            fi
        fi
        
        echo -e "${GREEN}✅ NVIDIA drivers installed${NC}"
        echo -e "${YELLOW}⚠ Remember to add nvidia modules to mkinitcpio and regenerate initramfs${NC}"
    else
        echo -e "${RED}No NVIDIA GPU detected. Skipping...${NC}"
    fi
fi

# OpenTabletDriver
read -rp "Do you have a drawing tablet? Install OpenTabletDriver? (y/n): " install_otd
if [[ "$install_otd" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing OpenTabletDriver...${NC}"
    yay -S --noconfirm opentabletdriver
    systemctl --user enable opentabletdriver.service --now
    echo -e "${GREEN}✅ OpenTabletDriver installed and enabled${NC}"
fi

# KeePassXC
read -rp "Install KeePassXC password manager? (y/n): " install_keepass
if [[ "$install_keepass" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing KeePassXC...${NC}"
    install_if_missing keepassxc
    echo -e "${GREEN}✅ KeePassXC installed${NC}"
fi

# VeraCrypt
read -rp "Install VeraCrypt for disk encryption? (y/n): " install_veracrypt
if [[ "$install_veracrypt" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing VeraCrypt...${NC}"
    install_if_missing veracrypt
    install_if_missing ntfs-3g
    echo -e "${GREEN}✅ VeraCrypt installed${NC}"
fi

# Secure Boot with sbctl
read -rp "Setup Secure Boot with sbctl? (y/n): " setup_sb
if [[ "$setup_sb" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing sbctl...${NC}"
    install_if_missing sbctl
    
    echo -e "${YELLOW}Current Secure Boot status:${NC}"
    sudo sbctl status || true
    
    echo
    read -rp "Create and enroll Secure Boot keys now? (y/n): " enroll_keys
    if [[ "$enroll_keys" =~ ^[Yy]$ ]]; then
        sudo sbctl create-keys
        sudo sbctl enroll-keys --microsoft
        echo -e "${GREEN}✅ Secure Boot keys enrolled${NC}"
        echo -e "${YELLOW}⚠ Reboot and enable Secure Boot in BIOS/UEFI${NC}"
    fi
fi

# Additional utilities
echo
read -rp "Install additional useful utilities? (kate, firefox, etc.) (y/n): " install_extras
if [[ "$install_extras" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing additional utilities...${NC}"
    
    EXTRA_PKGS=(
        firefox
        kate
        dolphin
        konsole
        gwenview
        spectacle
        vlc
    )
    
    echo "Available packages:"
    for i in "${!EXTRA_PKGS[@]}"; do
        echo "$((i+1))) ${EXTRA_PKGS[$i]}"
    done
    
    read -rp "Enter package numbers to install (space-separated, or 'all'): " selection
    
    if [[ "$selection" == "all" ]]; then
        for pkg in "${EXTRA_PKGS[@]}"; do
            install_if_missing "$pkg"
        done
    else
        for num in $selection; do
            idx=$((num-1))
            if [[ $idx -ge 0 && $idx -lt ${#EXTRA_PKGS[@]} ]]; then
                install_if_missing "${EXTRA_PKGS[$idx]}"
            fi
        done
    fi
fi

echo
echo -e "${GREEN}✅ Optional components setup complete!${NC}"
