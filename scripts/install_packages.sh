#!/usr/bin/env bash
# ===============================================
#  Core Hyprland Package Installer
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
echo -e "${GREEN}  Installing Core Packages${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

# Check for yay
if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}==> Installing yay AUR helper...${NC}"
    sudo pacman -S --needed git base-devel --noconfirm
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd - >/dev/null
    echo -e "${GREEN}✅ yay installed${NC}"
fi

# Core Hyprland packages
echo -e "${GREEN}==> Installing Hyprland and core components...${NC}"

HYPRLAND_CORE=(
    hyprland
    hypridle hyprlock hyprutils hyprsunset
    hyprpaper
)

for pkg in "${HYPRLAND_CORE[@]}"; do
    install_if_missing "$pkg"
done

# Essential tools for the config
echo -e "${GREEN}==> Installing essential tools...${NC}"

ESSENTIAL_TOOLS=(
    # System tools
    timeshift brightnessctl ddcutil
    
    # Utilities
    rofi-wayland kdialog ark
    starship fastfetch
    
    # Color/theming
    python-pywal python-pillow python-opencv bc
    
    # Network
    nm-connection-editor plasma-nm
    
    # Audio/Power
    upower
    
    # Clipboard/Screen
    cliphist
    
    # Apps
    xournalpp
    
    # Development
    breeze syntax-highlighting
)

for pkg in "${ESSENTIAL_TOOLS[@]}"; do
    install_if_missing "$pkg"
done

# AUR packages
echo -e "${GREEN}==> Installing AUR packages...${NC}"

AUR_PKGS=(
    quickshell
    wlogout
    python-materialyoucolor
    matugen-bin
    adw-gtk-theme-git
    breeze-plus
    ttf-jetbrains-mono-nerd
    ttf-twemoji
    mpvpaper
)

for pkg in "${AUR_PKGS[@]}"; do
    if yay -Q "$pkg" &>/dev/null; then
        echo -e "${YELLOW}✓ $pkg already installed${NC}"
    else
        echo -e "${GREEN}Installing $pkg from AUR...${NC}"
        yay -S --noconfirm "$pkg"
    fi
done

# Install Material Symbols fonts
echo -e "${GREEN}==> Installing Material Symbols fonts...${NC}"

FONT_DIR="$HOME/.local/share/fonts/material-symbols"
mkdir -p "$FONT_DIR"
cd "$FONT_DIR" || exit 1

BASE_URL="https://github.com/google/material-design-icons/raw/refs/heads/master"
FONT_PATHS=(
  "font/MaterialIcons-Regular.ttf"
  "font/MaterialIconsOutlined-Regular.otf"
  "font/MaterialIconsRound-Regular.otf"
  "font/MaterialIconsSharp-Regular.otf"
  "font/MaterialIconsTwoTone-Regular.otf"
  "variablefont/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf"
  "variablefont/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].woff2"
  "variablefont/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
  "variablefont/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].woff2"
  "variablefont/MaterialSymbolsSharp[FILL,GRAD,opsz,wght].ttf"
  "variablefont/MaterialSymbolsSharp[FILL,GRAD,opsz,wght].woff2"
)

for path in "${FONT_PATHS[@]}"; do
  encoded_path="${path//[/%5B}"
  encoded_path="${encoded_path//]/%5D}"
  filename="${path##*/}"
  echo "→ $filename"
  curl -sSfL "$BASE_URL/$encoded_path" -o "$filename" || echo "✗ Failed: $filename"
done

fc-cache -f "$HOME/.local/share/fonts"
echo -e "${GREEN}✅ Fonts installed${NC}"

# Python virtual environment setup
echo -e "${GREEN}==> Setting up Python environment...${NC}"

VENV_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
REQ_FILE="$SCRIPT_DIR/../sdata/uv/requirements.txt"

mkdir -p "$(dirname "$VENV_PATH")"
python3 -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"

if [[ -f "$REQ_FILE" ]]; then
    pip install --upgrade pip
    pip install -r "$REQ_FILE"
    echo -e "${GREEN}✅ Python packages installed${NC}"
else
    echo -e "${YELLOW}⚠ requirements.txt not found at $REQ_FILE${NC}"
fi

deactivate

# Install kde-material-you-colors via pipx
echo -e "${GREEN}==> Installing kde-material-you-colors...${NC}"
pipx install kde-material-you-colors || echo -e "${YELLOW}⚠ kde-material-you-colors install failed${NC}"

echo -e "${GREEN}✅ Core packages installation complete!${NC}"
