#!/usr/bin/env bash
# ===============================================
#  Optional Components Setup
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; BLUE='\033[1;34m'; NC='\033[0m'

# Error tracking
declare -a FAILED_PACKAGES=()
declare -a FAILED_AUR=()
CTRL_C_COUNT=0

# Trap Ctrl+C
trap 'handle_interrupt' INT

handle_interrupt() {
    CTRL_C_COUNT=$((CTRL_C_COUNT + 1))
    if [[ $CTRL_C_COUNT -eq 1 ]]; then
        echo -e "\n${YELLOW}⚠ Interrupt detected. Press Ctrl+C again to exit or wait to continue...${NC}"
        sleep 3
        CTRL_C_COUNT=0
    else
        echo -e "\n${RED}Exiting...${NC}"
        exit 130
    fi
}

install_if_missing() {
    local pkg="$1"
    if ! pacman -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}Installing $pkg...${NC}"
        if ! sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
            echo -e "${RED}✗ Failed to install $pkg${NC}"
            FAILED_PACKAGES+=("$pkg")
            return 1
        fi
    else
        echo -e "${YELLOW}✓ $pkg already installed${NC}"
    fi
    return 0
}

install_aur_if_missing() {
    local pkg="$1"
    if ! yay -Q "$pkg" &>/dev/null && ! pacman -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}Installing $pkg from AUR...${NC}"
        if ! yay -S --noconfirm "$pkg" 2>/dev/null; then
            echo -e "${RED}✗ Failed to install $pkg${NC}"
            FAILED_AUR+=("$pkg")
            return 1
        fi
    else
        echo -e "${YELLOW}✓ $pkg already installed${NC}"
    fi
    return 0
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
        install_if_missing nvidia || true
        install_if_missing nvidia-utils || true
        install_if_missing nvidia-settings || true
        
        # Check for laptop (optimus)
        if [[ -f /sys/class/dmi/id/chassis_type ]]; then
            chassis_type=$(cat /sys/class/dmi/id/chassis_type)
            # 8=Portable, 9=Laptop, 10=Notebook
            if [[ "$chassis_type" == "8" || "$chassis_type" == "9" || "$chassis_type" == "10" ]]; then
                echo -e "${YELLOW}Laptop detected. Consider installing nvidia-prime for Optimus support.${NC}"
                read -rp "Install nvidia-prime? (y/n): " install_prime
                if [[ "$install_prime" =~ ^[Yy]$ ]]; then
                    install_if_missing nvidia-prime || true
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
    if install_aur_if_missing opentabletdriver; then
        systemctl --user enable opentabletdriver.service --now || \
            echo -e "${YELLOW}⚠ Failed to enable OpenTabletDriver service${NC}"
        echo -e "${GREEN}✅ OpenTabletDriver installed and enabled${NC}"
    fi
fi

# KeePassXC
read -rp "Install KeePassXC password manager? (y/n): " install_keepass
if [[ "$install_keepass" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing KeePassXC...${NC}"
    if install_if_missing keepassxc; then
        echo -e "${GREEN}✅ KeePassXC installed${NC}"
    fi
fi

# VeraCrypt
read -rp "Install VeraCrypt for disk encryption? (y/n): " install_veracrypt
if [[ "$install_veracrypt" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing VeraCrypt...${NC}"
    install_if_missing veracrypt || true
    install_if_missing ntfs-3g || true
    echo -e "${GREEN}✅ VeraCrypt installed${NC}"
fi

# Secure Boot with sbctl
read -rp "Setup Secure Boot with sbctl? (y/n): " setup_sb
if [[ "$setup_sb" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing sbctl...${NC}"
    if install_if_missing sbctl; then
        echo -e "${YELLOW}Current Secure Boot status:${NC}"
        sudo sbctl status || true
        
        echo
        read -rp "Create and enroll Secure Boot keys now? (y/n): " enroll_keys
        if [[ "$enroll_keys" =~ ^[Yy]$ ]]; then
            if sudo sbctl create-keys && sudo sbctl enroll-keys --microsoft; then
                echo -e "${GREEN}✅ Secure Boot keys enrolled${NC}"
                echo -e "${YELLOW}⚠ Reboot and enable Secure Boot in BIOS/UEFI${NC}"
            else
                echo -e "${RED}✗ Failed to enroll Secure Boot keys${NC}"
                FAILED_PACKAGES+=("sbctl-enrollment")
            fi
        fi
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
        thunderbird
        libreoffice-fresh
    )
    
    echo "Available packages:"
    for i in "${!EXTRA_PKGS[@]}"; do
        echo "$((i+1))) ${EXTRA_PKGS[$i]}"
    done
    
    read -rp "Enter package numbers to install (space-separated, or 'all'): " selection
    
    if [[ "$selection" == "all" ]]; then
        for pkg in "${EXTRA_PKGS[@]}"; do
            install_if_missing "$pkg" || true
        done
    else
        for num in $selection; do
            idx=$((num-1))
            if [[ $idx -ge 0 && $idx -lt ${#EXTRA_PKGS[@]} ]]; then
                install_if_missing "${EXTRA_PKGS[$idx]}" || true
            fi
        done
    fi
fi

# Summary
echo
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Optional Setup Summary${NC}"
echo -e "${BLUE}=======================================${NC}"

if [[ ${#FAILED_PACKAGES[@]} -eq 0 ]] && [[ ${#FAILED_AUR[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ All optional components installed successfully!${NC}"
else
    echo -e "${YELLOW}⚠ Some packages failed to install:${NC}"
    
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        echo -e "${RED}Failed official packages:${NC}"
        printf '  - %s\n' "${FAILED_PACKAGES[@]}"
    fi
    
    if [[ ${#FAILED_AUR[@]} -gt 0 ]]; then
        echo -e "${RED}Failed AUR packages:${NC}"
        printf '  - %s\n' "${FAILED_AUR[@]}"
    fi
    
    echo
    echo -e "${YELLOW}You can try installing failed packages manually later.${NC}"
fi
