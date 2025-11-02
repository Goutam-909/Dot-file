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
declare -a INSTALLED_PACMAN=()
declare -a INSTALLED_AUR=()

# Cleanup function for interrupts
cleanup_pacman_lock() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        echo -e "\n${YELLOW}Cleaning up pacman lock...${NC}"
        sudo rm -f /var/lib/pacman/db.lck
        echo -e "${GREEN}✅ Lock file removed${NC}"
    fi
}

# Trap interrupts
trap 'cleanup_pacman_lock; exit 130' INT TERM

install_if_missing() {
    local pkg="$1"
    if ! pacman -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}Installing $pkg...${NC}"
        if sudo pacman -S --needed "$pkg"; then
            INSTALLED_PACMAN+=("$pkg")
            echo -e "${GREEN}✅ $pkg installed${NC}"
        else
            echo -e "${RED}✗ Failed to install $pkg${NC}"
            FAILED_PACKAGES+=("$pkg")
            cleanup_pacman_lock
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
        if yay -S "$pkg"; then
            INSTALLED_AUR+=("$pkg")
            echo -e "${GREEN}✅ $pkg installed${NC}"
        else
            echo -e "${RED}✗ Failed to install $pkg${NC}"
            FAILED_AUR+=("$pkg")
            cleanup_pacman_lock
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

# Gaming Support
read -rp "Install gaming support (Steam, Wine, etc.)? (y/N): " install_gaming
if [[ "$install_gaming" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Coming soon! Gaming support will be added in future updates.${NC}"
fi

# NVIDIA drivers
read -rp "Do you have an NVIDIA GPU? Install NVIDIA drivers? (y/N): " install_nvidia
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
                read -rp "Install nvidia-prime? (y/N): " install_prime
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
read -rp "Do you have a drawing tablet? Install OpenTabletDriver? (y/N): " install_otd
if [[ "$install_otd" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing OpenTabletDriver...${NC}"
    if install_aur_if_missing opentabletdriver; then
        systemctl --user enable opentabletdriver.service --now || \
            echo -e "${YELLOW}⚠ Failed to enable OpenTabletDriver service${NC}"
        echo -e "${GREEN}✅ OpenTabletDriver installed and enabled${NC}"
    fi
fi

# KeePassXC
read -rp "Install KeePassXC password manager? (y/N): " install_keepass
if [[ "$install_keepass" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing KeePassXC...${NC}"
    if install_if_missing keepassxc; then
        echo -e "${GREEN}✅ KeePassXC installed${NC}"
    fi
fi

# VeraCrypt
read -rp "Install VeraCrypt for disk encryption? (y/N): " install_veracrypt
if [[ "$install_veracrypt" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing VeraCrypt...${NC}"
    install_if_missing veracrypt || true
    install_if_missing ntfs-3g || true
    echo -e "${GREEN}✅ VeraCrypt installed${NC}"
fi

# Secure Boot with sbctl
read -rp "Setup Secure Boot with sbctl? (y/N): " setup_sb
if [[ "$setup_sb" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Checking Secure Boot status...${NC}"
    
    # Check if sbctl is installed
    if ! command -v sbctl &>/dev/null; then
        install_if_missing sbctl || exit 1
    fi
    
    # Check Secure Boot status
    echo -e "${YELLOW}Current Secure Boot status:${NC}"
    sudo sbctl status || true
    
    # Check if Setup Mode is enabled and Secure Boot is disabled
    if sudo sbctl status | grep -q "Setup Mode.*Enabled" && sudo sbctl status | grep -q "Secure Boot.*Disabled"; then
        echo -e "${GREEN}✓ Setup Mode enabled, Secure Boot disabled - ready for key enrollment${NC}"
        
        echo
        read -rp "Create and enroll Secure Boot keys now? (y/N): " enroll_keys
        if [[ "$enroll_keys" =~ ^[Yy]$ ]]; then
            if sudo sbctl create-keys && sudo sbctl enroll-keys --microsoft; then
                echo -e "${GREEN}✅ Secure Boot keys enrolled${NC}"
                
                # Sign bootloader and kernel files
                echo -e "${GREEN}==> Signing system files...${NC}"
                
                echo "Scanning for unsigned files..."
                sudo sbctl verify
                
                echo -e "${YELLOW}Signing all unsigned files...${NC}"
                # Sign all unsigned files automatically
                sudo sbctl verify | grep "is not signed" | awk '{print $2}' | while read -r file; do
                    if [[ -f "$file" ]]; then
                        echo "Signing: $file"
                        sudo sbctl sign -s "$file" 2>/dev/null || echo "Failed to sign: $file"
                    fi
                done
                
                # Sign systemd-boot specifically if it exists
                if [[ -f /usr/lib/systemd/boot/efi/systemd-bootx64.efi ]]; then
                    echo -e "${GREEN}Signing systemd-boot...${NC}"
                    sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi 2>/dev/null || true
                fi
                
                echo -e "${GREEN}✅ System files signed${NC}"
                echo -e "${YELLOW}Verification status:${NC}"
                sudo sbctl verify
                
                echo
                echo -e "${YELLOW}⚠ Next steps:${NC}"
                echo "  1. Reboot your system"
                echo "  2. Enter BIOS/UEFI settings"
                echo "  3. Enable Secure Boot"
                echo "  4. Save and exit"
            else
                echo -e "${RED}✗ Failed to enroll Secure Boot keys${NC}"
                FAILED_PACKAGES+=("sbctl-enrollment")
            fi
        fi
    else
        echo -e "${RED}✗ System not ready for Secure Boot setup${NC}"
        echo -e "${YELLOW}Requirements:${NC}"
        echo "  • Setup Mode must be Enabled"
        echo "  • Secure Boot must be Disabled"
        echo
        echo "Please:"
        echo "  1. Reboot into BIOS/UEFI"
        echo "  2. Clear/Reset Secure Boot keys"
        echo "  3. Disable Secure Boot"
        echo "  4. Save and reboot"
        echo "  5. Run this script again"
    fi
fi

# Additional utilities
echo
read -rp "Install additional useful utilities? (y/N): " install_extras
if [[ "$install_extras" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing additional utilities...${NC}"
    
    EXTRA_PKGS=(
        firefox
        kate
        okular
        konsole
        loupe
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

if [[ ${#INSTALLED_PACMAN[@]} -gt 0 ]]; then
    echo -e "${GREEN}Installed from official repos (${#INSTALLED_PACMAN[@]}):${NC}"
    printf '  ✓ %s\n' "${INSTALLED_PACMAN[@]}"
fi

if [[ ${#INSTALLED_AUR[@]} -gt 0 ]]; then
    echo -e "${GREEN}Installed from AUR (${#INSTALLED_AUR[@]}):${NC}"
    printf '  ✓ %s\n' "${INSTALLED_AUR[@]}"
fi

if [[ ${#FAILED_PACKAGES[@]} -eq 0 ]] && [[ ${#FAILED_AUR[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ All optional components installed successfully!${NC}"
else
    echo -e "${YELLOW}⚠ Some packages failed to install:${NC}"
    
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        echo -e "${RED}Failed official packages:${NC}"
        printf '  ✗ %s\n' "${FAILED_PACKAGES[@]}"
    fi
    
    if [[ ${#FAILED_AUR[@]} -gt 0 ]]; then
        echo -e "${RED}Failed AUR packages:${NC}"
        printf '  ✗ %s\n' "${FAILED_AUR[@]}"
    fi
fi
