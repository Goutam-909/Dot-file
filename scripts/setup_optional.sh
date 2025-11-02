#!/usr/bin/env bash
# ===============================================
#  Optional Components Setup
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; BLUE='\033[1;34m'; NC='\033[0m'

# Log file
LOG_FILE="$HOME/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"

# Error tracking
declare -a FAILED_PACKAGES=()
declare -a FAILED_AUR=()

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

log_package() {
    local pkg="$1"
    local source="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installed: $pkg (from $source)" >> "$LOG_FILE"
}

install_package() {
    local pkg="$1"
    if ! pacman -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}Installing $pkg...${NC}"
        if sudo pacman -S --needed --noconfirm "$pkg"; then
            log_package "$pkg" "pacman"
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

install_aur_package() {
    local pkg="$1"
    if ! yay -Q "$pkg" &>/dev/null && ! pacman -Q "$pkg" &>/dev/null; then
        echo -e "${GREEN}Installing $pkg from AUR...${NC}"
        if yay -S --noconfirm "$pkg"; then
            log_package "$pkg" "AUR"
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
echo -e "${BLUE}Log file: $LOG_FILE${NC}"
echo

echo -e "${YELLOW}Select components to install:${NC}"
echo "1) NVIDIA drivers"
echo "2) OpenTabletDriver (drawing tablets)"
echo "3) KeePassXC (password manager)"
echo "4) VeraCrypt (disk encryption)"
echo "5) Secure Boot setup (sbctl)"
echo "6) Additional apps (Firefox, Kate, Okular, etc.)"
echo "7) Install all above"
echo "8) Skip optional components"
echo
read -rp "Enter your choice [1-8]: " choice

case "$choice" in
    1|7)
        # NVIDIA drivers
        echo -e "${GREEN}==> Installing NVIDIA drivers...${NC}"
        
        if lspci | grep -i nvidia &>/dev/null; then
            install_package nvidia || true
            install_package nvidia-utils || true
            install_package nvidia-settings || true
            
            # Check for laptop
            if [[ -f /sys/class/dmi/id/chassis_type ]]; then
                chassis_type=$(cat /sys/class/dmi/id/chassis_type)
                if [[ "$chassis_type" == "8" || "$chassis_type" == "9" || "$chassis_type" == "10" ]]; then
                    install_package nvidia-prime || true
                fi
            fi
            
            echo -e "${GREEN}✅ NVIDIA drivers installed${NC}"
            echo -e "${YELLOW}⚠ Add nvidia modules to mkinitcpio and regenerate initramfs${NC}"
        else
            echo -e "${RED}No NVIDIA GPU detected. Skipping...${NC}"
        fi
        ;&
esac

case "$choice" in
    2|7)
        # OpenTabletDriver
        echo -e "${GREEN}==> Installing OpenTabletDriver...${NC}"
        if install_aur_package opentabletdriver; then
            systemctl --user enable opentabletdriver.service --now || true
            echo -e "${GREEN}✅ OpenTabletDriver installed${NC}"
        fi
        ;&
esac

case "$choice" in
    3|7)
        # KeePassXC
        echo -e "${GREEN}==> Installing KeePassXC...${NC}"
        install_package keepassxc || true
        ;&
esac

case "$choice" in
    4|7)
        # VeraCrypt
        echo -e "${GREEN}==> Installing VeraCrypt...${NC}"
        install_package veracrypt || true
        install_package ntfs-3g || true
        ;&
esac

case "$choice" in
    5|7)
        # Secure Boot
        echo -e "${GREEN}==> Setting up Secure Boot...${NC}"
        
        if ! command -v sbctl &>/dev/null; then
            install_package sbctl || exit 1
        fi
        
        echo -e "${YELLOW}Current Secure Boot status:${NC}"
        sudo sbctl status || true
        
        if sudo sbctl status | grep -q "Setup Mode.*Enabled" && sudo sbctl status | grep -q "Secure Boot.*Disabled"; then
            echo -e "${GREEN}✓ System ready for Secure Boot setup${NC}"
            
            if sudo sbctl create-keys && sudo sbctl enroll-keys --microsoft; then
                echo -e "${GREEN}✅ Secure Boot keys enrolled${NC}"
                
                echo -e "${GREEN}==> Signing system files...${NC}"
                sudo sbctl verify
                
                sudo sbctl verify | grep "is not signed" | awk '{print $2}' | while read -r file; do
                    if [[ -f "$file" ]]; then
                        sudo sbctl sign -s "$file" 2>/dev/null || true
                    fi
                done
                
                if [[ -f /usr/lib/systemd/boot/efi/systemd-bootx64.efi ]]; then
                    sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi 2>/dev/null || true
                fi
                
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Configured: Secure Boot with sbctl" >> "$LOG_FILE"
                echo -e "${GREEN}✅ System files signed${NC}"
                sudo sbctl verify
            else
                echo -e "${RED}✗ Failed to setup Secure Boot${NC}"
            fi
        else
            echo -e "${RED}✗ System not ready for Secure Boot${NC}"
            echo "Requirements: Setup Mode Enabled + Secure Boot Disabled"
        fi
        ;&
esac

case "$choice" in
    6|7)
        # Additional apps
        echo -e "${GREEN}==> Installing additional apps...${NC}"
        
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
        
        for pkg in "${EXTRA_PKGS[@]}"; do
            install_package "$pkg" || true
        done
        ;&
esac

# Summary
echo
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Optional Setup Summary${NC}"
echo -e "${BLUE}=======================================${NC}"

if [[ ${#FAILED_PACKAGES[@]} -eq 0 ]] && [[ ${#FAILED_AUR[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ All optional components installed successfully!${NC}"
else
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        echo -e "${RED}Failed official packages:${NC}"
        printf '  ✗ %s\n' "${FAILED_PACKAGES[@]}"
    fi
    
    if [[ ${#FAILED_AUR[@]} -gt 0 ]]; then
        echo -e "${RED}Failed AUR packages:${NC}"
        printf '  ✗ %s\n' "${FAILED_AUR[@]}"
    fi
fi

echo -e "${BLUE}Installation log: $LOG_FILE${NC}"