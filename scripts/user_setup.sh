#!/usr/bin/env bash
# ===============================================
#  User Configuration Setup
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

declare -a MODIFICATIONS=()

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Setting Up User Configurations${NC}"
echo -e "${GREEN}=======================================${NC}"
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
        
        echo -e "${GREEN}✅ Backup created at: $BACKUP_DIR${NC}"
        MODIFICATIONS+=("Backup created: $BACKUP_DIR")
    else
        echo -e "${YELLOW}Skipping backup...${NC}"
    fi
fi

# Copy .config
if [[ -d "$SCRIPT_DIR/../config" ]]; then
    echo -e "${GREEN}==> Copying config files to ~/.config${NC}"
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR/../config/"* "$HOME/.config/"
    echo -e "${GREEN}✅ Config files copied${NC}"
    MODIFICATIONS+=("Copied dotfiles to ~/.config")
else
    echo -e "${RED}⚠ config directory not found!${NC}"
fi

# Copy .local
if [[ -d "$SCRIPT_DIR/../local" ]]; then
    echo -e "${GREEN}==> Copying local files to ~/.local${NC}"
    mkdir -p "$HOME/.local"
    cp -r "$SCRIPT_DIR/../local/"* "$HOME/.local/"
    echo -e "${GREEN}✅ Local files copied${NC}"
    MODIFICATIONS+=("Copied files to ~/.local")
else
    echo -e "${YELLOW}⚠ local directory not found, skipping...${NC}"
fi

# Set permissions
echo -e "${GREEN}==> Setting file permissions...${NC}"

# Make scripts executable
find "$HOME/.config" "$HOME/.local" -type f \( \
    -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; 2>/dev/null

# Make specific config files readable (not executable)
find "$HOME/.config" "$HOME/.local" -type f \( \
    -name "*.json" -o -name "*.toml" -o -name "*.txt" -o -name "*.css" -o -name "*.conf" \) -exec chmod 644 {} \; 2>/dev/null

echo -e "${GREEN}✅ Permissions set${NC}"
MODIFICATIONS+=("Set file permissions")

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
        MODIFICATIONS+=("Added Qt/Wayland environment variables")
    fi
fi

# Update XDG user directories
echo -e "${GREEN}==> Creating XDG user directories...${NC}"
if command -v xdg-user-dirs-update &>/dev/null; then
    xdg-user-dirs-update
    echo -e "${GREEN}✅ XDG user directories created/updated${NC}"
    MODIFICATIONS+=("Created XDG user directories")
    
    # List created directories
    echo -e "${YELLOW}Standard directories:${NC}"
    xdg-user-dir DESKTOP 2>/dev/null && echo "  ✓ Desktop: $(xdg-user-dir DESKTOP)"
    xdg-user-dir DOWNLOAD 2>/dev/null && echo "  ✓ Downloads: $(xdg-user-dir DOWNLOAD)"
    xdg-user-dir TEMPLATES 2>/dev/null && echo "  ✓ Templates: $(xdg-user-dir TEMPLATES)"
    xdg-user-dir PUBLICSHARE 2>/dev/null && echo "  ✓ Public: $(xdg-user-dir PUBLICSHARE)"
    xdg-user-dir DOCUMENTS 2>/dev/null && echo "  ✓ Documents: $(xdg-user-dir DOCUMENTS)"
    xdg-user-dir MUSIC 2>/dev/null && echo "  ✓ Music: $(xdg-user-dir MUSIC)"
    xdg-user-dir PICTURES 2>/dev/null && echo "  ✓ Pictures: $(xdg-user-dir PICTURES)"
    xdg-user-dir VIDEOS 2>/dev/null && echo "  ✓ Videos: $(xdg-user-dir VIDEOS)"
else
    echo -e "${YELLOW}⚠ xdg-user-dirs not installed, creating manually...${NC}"
    mkdir -p "$HOME/Desktop" "$HOME/Downloads" "$HOME/Documents" \
             "$HOME/Music" "$HOME/Pictures" "$HOME/Videos" \
             "$HOME/Templates" "$HOME/Public"
    echo -e "${GREEN}✅ Standard directories created${NC}"
    MODIFICATIONS+=("Created standard user directories")
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
    MODIFICATIONS+=("Created wallpaper directory")
else
    echo -e "${GREEN}✓ Wallpaper directory exists${NC}"
fi

# SDDM Theme Setup
echo
read -rp "Would you like to install SDDM Hyprland theme? (y/N): " install_sddm_theme
if [[ "$install_sddm_theme" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing SDDM Hyprland theme...${NC}"
    
    # Clone the theme
    if [[ ! -d /tmp/sddm-hyprland ]]; then
        git clone https://github.com/HyDE-Project/sddm-hyprland /tmp/sddm-hyprland
    fi
    
    cd /tmp/sddm-hyprland
    
    # Install theme
    if sudo make install 2>/dev/null; then
        echo -e "${GREEN}✅ SDDM Hyprland theme installed${NC}"
        MODIFICATIONS+=("Installed SDDM Hyprland theme")
        
        # Configure SDDM to use the theme
        SDDM_CONF="/etc/sddm.conf.d/hyprland.conf"
        sudo mkdir -p /etc/sddm.conf.d
        
        echo -e "${YELLOW}Configuring SDDM...${NC}"
        sudo tee "$SDDM_CONF" > /dev/null << 'EOF'
[Theme]
Current=sddm-hyprland
EOF
        
        echo -e "${GREEN}✅ SDDM configured to use Hyprland theme${NC}"
        MODIFICATIONS+=("Configured SDDM theme")
    else
        echo -e "${RED}✗ Failed to install SDDM theme${NC}"
    fi
    
    cd - > /dev/null
fi

# Enable required services
echo -e "${GREEN}==> Enabling services...${NC}"

# NetworkManager
if systemctl is-enabled NetworkManager.service &>/dev/null; then
    echo -e "${GREEN}✓ NetworkManager already enabled${NC}"
else
    sudo systemctl enable NetworkManager.service
    echo -e "${GREEN}✅ NetworkManager enabled${NC}"
    MODIFICATIONS+=("Enabled NetworkManager")
fi

# Create initial cache directories
echo -e "${GREEN}==> Creating cache directories...${NC}"
mkdir -p "$HOME/.cache/quickshell"
mkdir -p "$HOME/.cache/matugen"
mkdir -p "$HOME/.cache/hypr"
echo -e "${GREEN}✅ Cache directories created${NC}"

# Verify fonts installation
echo -e "${GREEN}==> Verifying fonts installation...${NC}"
if fc-list | grep -q "JetBrainsMono"; then
    echo -e "${GREEN}✓ JetBrains Mono Nerd Font detected${NC}"
else
    echo -e "${YELLOW}⚠ JetBrains Mono Nerd Font not found${NC}"
fi

if fc-list | grep -q "Material"; then
    echo -e "${GREEN}✓ Material Symbols fonts detected${NC}"
else
    echo -e "${YELLOW}⚠ Material Symbols fonts not found${NC}"
fi

echo
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}✅ User Configuration Complete!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo
echo "Configuration installed successfully!"
echo

# Print modifications summary
if [[ ${#MODIFICATIONS[@]} -gt 0 ]]; then
    echo -e "${BLUE}System modifications made:${NC}"
    printf '  • %s\n' "${MODIFICATIONS[@]}"
    echo
fi

echo "Next steps:"
echo "1. Log out of your current session"
echo "2. Select 'Hyprland' from SDDM login manager"
echo "3. Use MOD+Q to open QuickShell launcher"
echo
echo "Key bindings:"
echo "  MOD = Super (Windows key)"
echo "  MOD+Q = Application launcher"
echo "  MOD+Return = Kitty terminal"
echo "  MOD+E = Dolphin file manager"
echo
echo "Directories created:"
echo "  📁 ~/Desktop"
echo "  📁 ~/Downloads"
echo "  📁 ~/Documents"
echo "  📁 ~/Music"
echo "  📁 ~/Pictures"
echo "  📁 ~/Videos"
echo "  📁 ~/Pictures/wallpapers (add your wallpapers here)"
echo
