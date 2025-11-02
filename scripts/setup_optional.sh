#!/usr/bin/env bash
# ===============================================
#  Optional Components Setup
# ===============================================

set -e

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; BLUE='\033[1;34m'; NC='\033[0m'

# Cleanup lock on interrupt
trap 'sudo rm -f /var/lib/pacman/db.lck 2>/dev/null; exit 130' INT TERM

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Optional Components${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# Gaming Support
read -rp "Install gaming support? (y/N): " install_gaming
if [[ "$install_gaming" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Coming soon!${NC}"
fi

# NVIDIA drivers
read -rp "Install NVIDIA drivers? (y/N): " install_nvidia
if [[ "$install_nvidia" =~ ^[Yy]$ ]]; then
    if lspci | grep -i nvidia &>/dev/null; then
        if ! pacman -Q nvidia &>/dev/null; then
            sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
        fi
        
        # Check for laptop
        if [[ -f /sys/class/dmi/id/chassis_type ]]; then
            chassis_type=$(cat /sys/class/dmi/id/chassis_type)
            if [[ "$chassis_type" == "8" || "$chassis_type" == "9" || "$chassis_type" == "10" ]]; then
                read -rp "Install nvidia-prime for laptop? (y/N): " install_prime
                if [[ "$install_prime" =~ ^[Yy]$ ]]; then
                    if ! pacman -Q nvidia-prime &>/dev/null; then
                        sudo pacman -S --needed --noconfirm nvidia-prime
                    fi
                fi
            fi
        fi
    else
        echo -e "${RED}No NVIDIA GPU detected${NC}"
    fi
fi

# OpenTabletDriver
read -rp "Install OpenTabletDriver? (y/N): " install_otd
if [[ "$install_otd" =~ ^[Yy]$ ]]; then
    if ! pacman -Q opentabletdriver &>/dev/null && ! yay -Q opentabletdriver &>/dev/null; then
        yay -S --noconfirm opentabletdriver
        systemctl --user enable opentabletdriver.service --now
    fi
fi

# KeePassXC
read -rp "Install KeePassXC? (y/N): " install_keepass
if [[ "$install_keepass" =~ ^[Yy]$ ]]; then
    if ! pacman -Q keepassxc &>/dev/null; then
        sudo pacman -S --needed --noconfirm keepassxc
    fi
fi

# VeraCrypt
read -rp "Install VeraCrypt? (y/N): " install_veracrypt
if [[ "$install_veracrypt" =~ ^[Yy]$ ]]; then
    if ! pacman -Q veracrypt &>/dev/null; then
        sudo pacman -S --needed --noconfirm veracrypt ntfs-3g
    fi
fi

# Secure Boot
read -rp "Setup Secure Boot with sbctl? (y/N): " setup_sb
if [[ "$setup_sb" =~ ^[Yy]$ ]]; then
    if ! command -v sbctl &>/dev/null; then
        sudo pacman -S --needed --noconfirm sbctl
    fi
    
    echo -e "${YELLOW}Current Secure Boot status:${NC}"
    sudo sbctl status
    
    if sudo sbctl status | grep -q "Setup Mode.*Enabled" && sudo sbctl status | grep -q "Secure Boot.*Disabled"; then
        read -rp "Enroll Secure Boot keys? (y/N): " enroll_keys
        if [[ "$enroll_keys" =~ ^[Yy]$ ]]; then
            sudo sbctl create-keys
            sudo sbctl enroll-keys --microsoft
            
            echo -e "${GREEN}Signing system files...${NC}"
            sudo sbctl verify
            
            sudo sbctl verify | grep "is not signed" | awk '{print $2}' | while read -r file; do
                if [[ -f "$file" ]]; then
                    sudo sbctl sign -s "$file" 2>/dev/null || true
                fi
            done
            
            if [[ -f /usr/lib/systemd/boot/efi/systemd-bootx64.efi ]]; then
                sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi 2>/dev/null || true
            fi
            
            sudo sbctl verify
            echo -e "${GREEN}✅ Secure Boot setup complete${NC}"
        fi
    else
        echo -e "${RED}System not ready. Enable Setup Mode and disable Secure Boot in BIOS${NC}"
    fi
fi

# Additional apps
read -rp "Install additional apps? (y/N): " install_extras
if [[ "$install_extras" =~ ^[Yy]$ ]]; then
    EXTRA_PKGS=(firefox kate okular konsole loupe spectacle vlc thunderbird libreoffice-fresh)
    
    echo "Available:"
    for i in "${!EXTRA_PKGS[@]}"; do
        echo "$((i+1))) ${EXTRA_PKGS[$i]}"
    done
    
    read -rp "Enter numbers (space-separated) or 'all': " selection
    
    if [[ "$selection" == "all" ]]; then
        for pkg in "${EXTRA_PKGS[@]}"; do
            if ! pacman -Q "$pkg" &>/dev/null; then
                sudo pacman -S --needed --noconfirm "$pkg" || true
            fi
        done
    else
        for num in $selection; do
            idx=$((num-1))
            if [[ $idx -ge 0 && $idx -lt ${#EXTRA_PKGS[@]} ]]; then
                pkg="${EXTRA_PKGS[$idx]}"
                if ! pacman -Q "$pkg" &>/dev/null; then
                    sudo pacman -S --needed --noconfirm "$pkg" || true
                fi
            fi
        done
    fi
fi

echo -e "${GREEN}✅ Optional setup complete!${NC}"
