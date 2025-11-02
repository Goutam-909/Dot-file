#!/usr/bin/env bash
# ===============================================
#  User Configuration Setup
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

# Log file
LOG_FILE="$HOME/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Setting Up User Configurations${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e "${BLUE}Log file: $LOG_FILE${NC}"
echo

# Backup existing configs
if [[ -d "$HOME/.config/hypr" ]] || [[ -d "$HOME/.config/quickshell" ]]; then
    echo -e "${YELLOW}Existing configs detected.${NC}"
    read -rp "Create backup of existing configurations? (y/N): " create_backup
    
    if [[ "$create_backup" =~ ^[Yy]$ ]]; then
        BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        [[ -d "$HOME/.config/hypr" ]] && cp -r "$HOME/.config/hypr" "$BACKUP_DIR/"
        [[ -d "$HOME/.config/quickshell" ]] && cp -r "$HOME/.config/quickshell" "$BACKUP_DIR/"
        [[ -d "$HOME/.config/rofi" ]] && cp -r "$HOME/.config/rofi" "$BACKUP_DIR/"
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Created backup: $BACKUP_DIR" >> "$LOG_FILE"
        echo -e "${GREEN}✅ Backup created at: $BACKUP_DIR${NC}"
    fi
fi

# Copy .config
if [[ -d "$SCRIPT_DIR/../config" ]]; then
    echo -e "${GREEN}==> Copying config files to ~/.config${NC}"
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR/../config/"* "$HOME/.config/"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Copied: Dotfiles to ~/.config" >> "$LOG_FILE"
    echo -e "${GREEN}✅ Config files copied${NC}"
else
    echo -e "${RED}⚠ config directory not found!${NC}"
fi

# Copy .local
if [[ -d "$SCRIPT_DIR/../local" ]]; then
    echo -e "${GREEN}==> Copying local files to ~/.local${NC}"
    mkdir -p "$HOME/.local"
    cp -r "$SCRIPT_DIR/../local/"* "$HOME/.local/"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Copied: Files to ~/.local" >> "$LOG_FILE"
    echo -e "${GREEN}✅ Local files copied${NC}"
fi

# Set permissions
echo -e "${GREEN}==> Setting file permissions...${NC}"
find "$HOME/.config" "$HOME/.local" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; 2>/dev/null
find "$HOME/.config" "$HOME/.local" -type f \( -name "*.json" -o -name "*.toml" -o -name "*.txt" -o -name "*.css" -o -name "*.conf" \) -exec chmod 644 {} \; 2>/dev/null
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Modified: Set file permissions" >> "$LOG_FILE"
echo -e "${GREEN}✅ Permissions set${NC}"

# Set environment variables
echo -e "${GREEN}==> Configuring environment...${NC}"
ENV_FILE="$HOME/.config/hypr/hyprland.conf"
if [[ -f "$ENV_FILE" ]]; then
    if ! grep -q "QT_QPA_PLATFORM" "$ENV_FILE"; then
        cat >> "$ENV_FILE" << 'EOF'

# Qt/Wayland environment
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,kde
env = XDG_MENU_PREFIX,plasma-
EOF
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Modified: Added Qt/Wayland env vars to hyprland.conf" >> "$LOG_FILE"
    fi
fi

# XDG directories
echo -e "${GREEN}==> Creating XDG user directories...${NC}"
if command -v xdg-user-dirs-update &>/dev/null; then
    xdg-user-dirs-update
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Created: XDG user directories" >> "$LOG_FILE"
    echo -e "${GREEN}✅ XDG user directories created${NC}"
else
    mkdir -p "$HOME/Desktop" "$HOME/Downloads" "$HOME/Documents" \
             "$HOME/Music" "$HOME/Pictures" "$HOME/Videos" \
             "$HOME/Templates" "$HOME/Public"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Created: Standard user directories" >> "$LOG_FILE"
    echo -e "${GREEN}✅ Standard directories created${NC}"
fi

# Wallpaper directory
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    mkdir -p "$WALLPAPER_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Created: Wallpaper directory" >> "$LOG_FILE"
fi

# SDDM Theme
echo
read -rp "Install SDDM Hyprland theme? (y/N): " install_sddm_theme
if [[ "$install_sddm_theme" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing SDDM Hyprland theme...${NC}"
    
    if [[ ! -d /tmp/sddm-hyprland ]]; then
        git clone https://github.com/HyDE-Project/sddm-hyprland /tmp/sddm-hyprland
    fi
    
    cd /tmp/sddm-hyprland
    
    if sudo make install 2>/dev/null; then
        sudo mkdir -p /etc/sddm.conf.d
        sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null << 'EOF'
[Theme]
Current=sddm-hyprland
EOF
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installed: SDDM Hyprland theme" >> "$LOG_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Modified: SDDM configuration" >> "$LOG_FILE"
        echo -e "${GREEN}✅ SDDM theme installed and configured${NC}"
    else
        echo -e "${RED}✗ Failed to install SDDM theme${NC}"
    fi
    
    cd - > /dev/null
fi

# Enable services
echo -e "${GREEN}==> Enabling services...${NC}"
if ! systemctl is-enabled NetworkManager.service &>/dev/null; then
    sudo systemctl enable NetworkManager.service
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Enabled: NetworkManager service" >> "$LOG_FILE"
fi

# Cache directories
mkdir -p "$HOME/.cache/quickshell"
mkdir -p "$HOME/.cache/matugen"
mkdir -p "$HOME/.cache/hypr"

# Verify fonts
echo -e "${GREEN}==> Verifying fonts...${NC}"
fc-list | grep -q "JetBrainsMono" && echo -e "${GREEN}✓ JetBrains Mono Nerd Font${NC}"
fc-list | grep -q "Material" && echo -e "${GREEN}✓ Material Symbols fonts${NC}"

echo
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}✅ User Configuration Complete!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo
echo "Configuration installed successfully!"
echo
echo "Next steps:"
echo "1. Log out of your current session"
echo "2. Select 'Hyprland' from SDDM"
echo "3. Use MOD+Q to open QuickShell launcher"
echo
echo -e "${BLUE}Installation log: $LOG_FILE${NC}"
echo