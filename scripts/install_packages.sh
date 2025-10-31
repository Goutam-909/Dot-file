#!/usr/bin/env bash
# ===============================================
#  Core Hyprland Package Installer
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

# Core Hyprland packages with graphics drivers
echo -e "${GREEN}==> Installing Hyprland and graphics drivers...${NC}"

HYPRLAND_CORE=(
    hyprland
    hypridle hyprlock hyprutils hyprsunset hyprpaper
    
    # Graphics drivers (multi-GPU support)
    mesa vulkan-tools
    
    # Intel
    intel-media-driver libva-intel-driver vulkan-intel
    
    # AMD
    libva-mesa-driver vulkan-radeon xf86-video-amdgpu xf86-video-ati
    
    # NVIDIA (nouveau)
    vulkan-nouveau xf86-video-nouveau
    
    # Xorg compatibility
    xorg-server xorg-xinit
)

for pkg in "${HYPRLAND_CORE[@]}"; do
    install_if_missing "$pkg" || true
done

# Display Manager - SDDM
echo -e "${GREEN}==> Installing SDDM display manager...${NC}"
install_if_missing "sddm"

if systemctl is-enabled sddm.service &>/dev/null; then
    echo -e "${GREEN}✓ SDDM already enabled${NC}"
else
    echo -e "${GREEN}Enabling SDDM...${NC}"
    sudo systemctl enable sddm.service
    echo -e "${GREEN}✅ SDDM enabled${NC}"
fi

# Terminal
echo -e "${GREEN}==> Installing terminal (Kitty)...${NC}"
install_if_missing "kitty"

# Essential tools for the config
echo -e "${GREEN}==> Installing essential tools...${NC}"

ESSENTIAL_TOOLS=(
    # System tools
    timeshift brightnessctl ddcutil
    
    # File managers
    dolphin
    kdegraphics-thumbnailers  # PDF thumbnails
    ffmpegthumbs              # Video thumbnails
    
    # Utilities
    rofi-wayland kdialog ark
    starship fastfetch
    
    # Color/theming
    python-pywal python-pillow python-opencv
    
    # Network
    nm-connection-editor plasma-nm
    
    # Audio/Power
    upower pipewire pipewire-pulse wireplumber
    
    # Clipboard/Screen
    cliphist
    
    # Apps
    xournalpp
    
    # Development
    breeze syntax-highlighting
)

for pkg in "${ESSENTIAL_TOOLS[@]}"; do
    install_if_missing "$pkg" || true
done

# Flatpak support
echo
read -rp "Install Flatpak and Flathub support? (y/n): " install_flatpak
if [[ "$install_flatpak" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}==> Installing Flatpak...${NC}"
    install_if_missing "flatpak"
    
    echo -e "${GREEN}Adding Flathub repository...${NC}"
    if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null; then
        echo -e "${GREEN}✅ Flathub added${NC}"
    else
        echo -e "${YELLOW}✓ Flathub already configured${NC}"
    fi
fi

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
    install_aur_if_missing "$pkg" || true
done

# Install Material Symbols fonts
echo -e "${GREEN}==> Installing Material Symbols fonts...${NC}"

FONT_DIR="$HOME/.local/share/fonts/material-symbols"

# Check if fonts already exist
if [[ -d "$FONT_DIR" ]] && [[ $(ls -A "$FONT_DIR" 2>/dev/null | wc -l) -gt 5 ]]; then
    echo -e "${YELLOW}✓ Material Symbols fonts already installed${NC}"
else
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
      if ! curl -sSfL "$BASE_URL/$encoded_path" -o "$filename" 2>/dev/null; then
          echo -e "${RED}✗ Failed: $filename${NC}"
      fi
    done

    fc-cache -f "$HOME/.local/share/fonts"
    echo -e "${GREEN}✅ Fonts installed${NC}"
fi

# Python virtual environment setup
echo -e "${GREEN}==> Setting up Python environment...${NC}"

VENV_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
REQ_FILE="$SCRIPT_DIR/../sdata/uv/requirements.txt"

mkdir -p "$(dirname "$VENV_PATH")"

if [[ ! -d "$VENV_PATH" ]]; then
    python3 -m venv "$VENV_PATH"
    echo -e "${GREEN}✅ Virtual environment created${NC}"
else
    echo -e "${YELLOW}✓ Virtual environment exists${NC}"
fi

source "$VENV_PATH/bin/activate"

if [[ -f "$REQ_FILE" ]]; then
    pip install --upgrade pip
    if pip install -r "$REQ_FILE" 2>/dev/null; then
        echo -e "${GREEN}✅ Python packages installed${NC}"
    else
        echo -e "${RED}✗ Some Python packages failed to install${NC}"
        FAILED_PACKAGES+=("python-requirements")
    fi
else
    echo -e "${YELLOW}⚠ requirements.txt not found at $REQ_FILE${NC}"
fi

deactivate

# Install kde-material-you-colors via pipx
echo -e "${GREEN}==> Installing kde-material-you-colors...${NC}"
if pipx list | grep -q "kde-material-you-colors"; then
    echo -e "${YELLOW}✓ kde-material-you-colors already installed${NC}"
else
    if pipx install kde-material-you-colors 2>/dev/null; then
        echo -e "${GREEN}✅ kde-material-you-colors installed${NC}"
    else
        echo -e "${RED}✗ kde-material-you-colors failed to install${NC}"
        FAILED_PACKAGES+=("kde-material-you-colors")
    fi
fi

# Summary
echo
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Installation Summary${NC}"
echo -e "${BLUE}=======================================${NC}"

if [[ ${#FAILED_PACKAGES[@]} -eq 0 ]] && [[ ${#FAILED_AUR[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ All packages installed successfully!${NC}"
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

echo -e "${GREEN}✅ Core packages installation complete!${NC}"
