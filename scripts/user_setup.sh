#!/usr/bin/env bash
# ===============================================
#  User Configuration Setup
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  User Configuration Setup${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

# Backup
if [[ -d "$HOME/.config/hypr" ]] || [[ -d "$HOME/.config/quickshell" ]]; then
    read -rp "Backup existing configs? (y/N): " create_backup
    
    if [[ "$create_backup" =~ ^[Yy]$ ]]; then
        BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        [[ -d "$HOME/.config/hypr" ]] && cp -r "$HOME/.config/hypr" "$BACKUP_DIR/"
        [[ -d "$HOME/.config/quickshell" ]] && cp -r "$HOME/.config/quickshell" "$BACKUP_DIR/"
        [[ -d "$HOME/.config/rofi" ]] && cp -r "$HOME/.config/rofi" "$BACKUP_DIR/"
        
        echo -e "${GREEN}✅ Backup: $BACKUP_DIR${NC}"
    fi
fi

# Copy configs
if [[ -d "$SCRIPT_DIR/../config" ]]; then
    echo -e "${GREEN}==> Copying configs...${NC}"
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR/../config/"* "$HOME/.config/"
fi

if [[ -d "$SCRIPT_DIR/../local" ]]; then
    echo -e "${GREEN}==> Copying local files...${NC}"
    mkdir -p "$HOME/.local"
    cp -r "$SCRIPT_DIR/../local/"* "$HOME/.local/"
fi
if [[ -d "$SCRIPT_DIR/../.bashrc" ]]; then
    echo -e "${GREEN}==> Copying Bash Config...${NC}"
    cp -r "$SCRIPT_DIR/../.bashrc" "$HOME/"
fi

# Permissions
echo -e "${GREEN}==> Setting permissions...${NC}"
find "$HOME/.config" "$HOME/.local" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; 2>/dev/null
find "$HOME/.config" "$HOME/.local" -type f \( -name "*.json" -o -name "*.toml" -o -name "*.txt" -o -name "*.css" -o -name "*.conf" \) -exec chmod 644 {} \; 2>/dev/null

# Environment variables
ENV_FILE="$HOME/.config/hypr/hyprland.conf"
if [[ -f "$ENV_FILE" ]] && ! grep -q "QT_QPA_PLATFORM" "$ENV_FILE"; then
    cat >> "$ENV_FILE" << 'EOF'

# Qt/Wayland environment
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,kde
env = XDG_MENU_PREFIX,plasma-
EOF
fi

# XDG directories
echo -e "${GREEN}==> Creating directories...${NC}"
if command -v xdg-user-dirs-update &>/dev/null; then
    xdg-user-dirs-update
else
    mkdir -p "$HOME/Desktop" "$HOME/Downloads" "$HOME/Documents" \
             "$HOME/Music" "$HOME/Pictures" "$HOME/Videos" \
             "$HOME/Templates" "$HOME/Public"
fi

mkdir -p "$HOME/Pictures/wallpapers"

# SDDM theme
read -rp "Install SDDM Hyprland theme? (y/N): " install_sddm_theme
if [[ "$install_sddm_theme" =~ ^[Yy]$ ]]; then
    if [[ ! -d /tmp/sddm-hyprland ]]; then
        git clone https://github.com/HyDE-Project/sddm-hyprland /tmp/sddm-hyprland
    fi
    
    cd /tmp/sddm-hyprland
    sudo make install
    
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null << 'EOF'
[Theme]
Current=sddm-hyprland
EOF
    
    cd - >/dev/null
    echo -e "${GREEN}✅ SDDM theme installed${NC}"
fi

# Enable services
if ! systemctl is-enabled NetworkManager.service &>/dev/null; then
    sudo systemctl enable NetworkManager.service
fi

# Cache directories
mkdir -p "$HOME/.cache/quickshell" "$HOME/.cache/matugen" "$HOME/.cache/hypr"

echo
echo -e "${GREEN}✅ Configuration complete!${NC}"
echo
echo "Next steps:"
echo "1. Log out"
echo "2. Select Hyprland from SDDM"
echo "3. Use MOD+Q for launcher"
echo
