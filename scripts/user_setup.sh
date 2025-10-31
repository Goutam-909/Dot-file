#!/usr/bin/env bash
# ===============================================
#  User Configuration Setup
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Setting Up User Configurations${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

# Backup existing configs
if [[ -d "$HOME/.config/hypr" ]] || [[ -d "$HOME/.config/quickshell" ]]; then
    echo -e "${YELLOW}Existing configs detected. Creating backup...${NC}"
    BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    [[ -d "$HOME/.config/hypr" ]] && cp -r "$HOME/.config/hypr" "$BACKUP_DIR/"
    [[ -d "$HOME/.config/quickshell" ]] && cp -r "$HOME/.config/quickshell" "$BACKUP_DIR/"
    [[ -d "$HOME/.config/rofi" ]] && cp -r "$HOME/.config/rofi" "$BACKUP_DIR/"
    
    echo -e "${GREEN}✅ Backup created at: $BACKUP_DIR${NC}"
fi

# Copy .config
if [[ -d "$SCRIPT_DIR/../config" ]]; then
    echo -e "${GREEN}==> Copying config files to ~/.config${NC}"
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR/../config/"* "$HOME/.config/"
    echo -e "${GREEN}✅ Config files copied${NC}"
else
    echo -e "${RED}⚠ config directory not found!${NC}"
fi

# Copy .local
if [[ -d "$SCRIPT_DIR/../local" ]]; then
    echo -e "${GREEN}==> Copying local files to ~/.local${NC}"
    mkdir -p "$HOME/.local"
    cp -r "$SCRIPT_DIR/../local/"* "$HOME/.local/"
    echo -e "${GREEN}✅ Local files copied${NC}"
else
    echo -e "${YELLOW}⚠ local directory not found, skipping...${NC}"
fi

# Set permissions
echo -e "${GREEN}==> Setting file permissions...${NC}"

# Make scripts executable
find "$HOME/.config" "$HOME/.local" -type f \( \
    -name "*.sh" -o \
    -name "*.py" \
) -exec chmod +x {} \; 2>/dev/null

# Make specific config files readable (not executable)
find "$HOME/.config" "$HOME/.local" -type f \( \
    -name "*.json" -o \
    -name "*.toml" -o \
    -name "*.txt" -o \
    -name "*.css" -o \
    -name "*.conf" \
) -exec chmod 644 {} \; 2>/dev/null

echo -e "${GREEN}✅ Permissions set${NC}"

# Set environment variables for Hyprland
echo -e "${GREEN}==> Configuring environment...${NC}"

ENV_FILE="$HOME/.config/hypr/hyprland.conf"
if [[ -f "$ENV_FILE" ]]; then
    # Verify Qt environment variables are set
    if grep -q "QT_QPA_PLATFORM" "$ENV_FILE"; then
        echo -e "${GREEN}✓ Qt environment variables found in hyprland.conf${NC}"
    else
        echo -e "${YELLOW}Adding Qt environment variables...${NC}"
        cat >> "$ENV_FILE" << 'EOF'

# Qt/Wayland environment
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,kde
env = XDG_MENU_PREFIX,plasma-
EOF
    fi
fi

# Verify Python venv
VENV_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
if [[ -d "$VENV_PATH" ]]; then
    echo -e "${GREEN}✓ Python venv found at $VENV_PATH${NC}"
else
    echo -e "${YELLOW}⚠ Python venv not found. Run install_packages.sh first.${NC}"
fi

# Initialize wallpaper directory
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo -e "${GREEN}==> Creating wallpaper directory...${NC}"
    mkdir -p "$WALLPAPER_DIR"
    echo -e "${GREEN}✅ Created $WALLPAPER_DIR${NC}"
    echo -e "${YELLOW}⚠ Add your wallpapers to this directory${NC}"
fi

# Enable required services
echo -e "${GREEN}==> Enabling services...${NC}"

# NetworkManager
if systemctl is-enabled NetworkManager.service &>/dev/null; then
    echo -e "${GREEN}✓ NetworkManager already enabled${NC}"
else
    sudo systemctl enable NetworkManager.service
    echo -e "${GREEN}✅ NetworkManager enabled${NC}"
fi

# Create initial cache directories
mkdir -p "$HOME/.cache/quickshell"
mkdir -p "$HOME/.cache/matugen"
mkdir -p "$HOME/.cache/hypr"

echo
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}✅ User Configuration Complete!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo
echo "Configuration installed successfully!"
echo
echo "Next steps:"
echo "1. Log out of your current session"
echo "2. Select 'Hyprland' from your login manager"
echo "3. Use MOD+Q to open QuickShell launcher"
echo
echo "Key bindings:"
echo "  MOD = Super (Windows key)"
echo "  MOD+Q = Application launcher"
echo "  MOD+Return = Terminal"
echo "  MOD+E = File manager"
echo
