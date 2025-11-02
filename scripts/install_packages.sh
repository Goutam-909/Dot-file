#!/usr/bin/env bash
# ===============================================
#  Core Hyprland Package Installer
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; BLUE='\033[1;34m'; NC='\033[0m'

# Cleanup lock on interrupt
trap 'sudo rm -f /var/lib/pacman/db.lck 2>/dev/null; exit 130' INT TERM

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Installing Core Packages${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

# Check for yay
if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}==> Installing yay AUR helper...${NC}"
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si
    cd - >/dev/null
    echo -e "${GREEN}✅ yay installed${NC}"
fi

# Core Hyprland packages
echo -e "${GREEN}==> Installing Hyprland and graphics drivers...${NC}"

HYPRLAND_CORE=(
    hyprland hypridle hyprlock hyprutils hyprsunset hyprpaper
    mesa vulkan-tools
    intel-media-driver libva-intel-driver vulkan-intel
    libva-mesa-driver vulkan-radeon xf86-video-amdgpu xf86-video-ati
    vulkan-nouveau xf86-video-nouveau
    xorg-server xorg-xinit
)

for pkg in "${HYPRLAND_CORE[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        sudo pacman -S --needed --noconfirm "$pkg" || true
    fi
done

# SDDM
echo -e "${GREEN}==> Installing SDDM...${NC}"
if ! pacman -Q sddm &>/dev/null; then
    sudo pacman -S --needed --noconfirm sddm
fi

if ! systemctl is-enabled sddm.service &>/dev/null; then
    sudo systemctl enable sddm.service
fi

# Terminal
echo -e "${GREEN}==> Installing Kitty...${NC}"
if ! pacman -Q kitty &>/dev/null; then
    sudo pacman -S --needed --noconfirm kitty
fi

# Essential tools
echo -e "${GREEN}==> Installing essential tools...${NC}"

ESSENTIAL_TOOLS=(
    timeshift brightnessctl ddcutil
    dolphin kdegraphics-thumbnailers ffmpegthumbs ffmpegthumbnailer
    rofi-wayland kdialog ark starship fastfetch
    python-pywal python-pillow python-opencv
    nm-connection-editor plasma-nm
    upower pipewire pipewire-pulse wireplumber
    cliphist xournalpp breeze syntax-highlighting
    xdg-user-dirs
)

for pkg in "${ESSENTIAL_TOOLS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        sudo pacman -S --needed --noconfirm "$pkg" || true
    fi
done

# Flatpak
echo
read -rp "Install Flatpak and Flathub? (y/N): " install_flatpak
if [[ "$install_flatpak" =~ ^[Yy]$ ]]; then
    if ! pacman -Q flatpak &>/dev/null; then
        sudo pacman -S --needed --noconfirm flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
fi

# AUR packages
echo -e "${GREEN}==> Installing AUR packages...${NC}"

AUR_PKGS=(
    quickshell wlogout python-materialyoucolor matugen-bin
    adw-gtk-theme-git breeze-plus ttf-twemoji mpvpaper
)

for pkg in "${AUR_PKGS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null && ! yay -Q "$pkg" &>/dev/null; then
        yay -S --noconfirm "$pkg" || true
    fi
done

# JetBrains Mono Nerd Font
echo -e "${GREEN}==> Installing JetBrains Mono Nerd Font...${NC}"

JETBRAINS_FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
if [[ ! -d "$JETBRAINS_FONT_DIR" ]] || [[ $(ls -A "$JETBRAINS_FONT_DIR" 2>/dev/null | wc -l) -eq 0 ]]; then
    mkdir -p "$JETBRAINS_FONT_DIR"
    cd "$JETBRAINS_FONT_DIR"
    curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o JetBrainsMono.zip
    unzip -oq JetBrainsMono.zip
    rm JetBrainsMono.zip
    cd - >/dev/null
fi

# Material Symbols fonts
echo -e "${GREEN}==> Installing Material Symbols fonts...${NC}"

FONT_DIR="$HOME/.local/share/fonts/material-symbols"
if [[ ! -d "$FONT_DIR" ]] || [[ $(ls -A "$FONT_DIR" 2>/dev/null | wc -l) -lt 5 ]]; then
    mkdir -p "$FONT_DIR"
    cd "$FONT_DIR"
    
    BASE_URL="https://github.com/google/material-design-icons/raw/refs/heads/master"
    FONT_PATHS=(
      "font/MaterialIcons-Regular.ttf"
      "font/MaterialIconsOutlined-Regular.otf"
      "font/MaterialIconsRound-Regular.otf"
      "font/MaterialIconsSharp-Regular.otf"
      "font/MaterialIconsTwoTone-Regular.otf"
      "variablefont/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf"
      "variablefont/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
      "variablefont/MaterialSymbolsSharp[FILL,GRAD,opsz,wght].ttf"
    )
    
    for path in "${FONT_PATHS[@]}"; do
        encoded_path="${path//[/%5B}"
        encoded_path="${encoded_path//]/%5D}"
        filename="${path##*/}"
        curl -fsSL "$BASE_URL/$encoded_path" -o "$filename" || true
    done
    
    cd - >/dev/null
fi

fc-cache -f "$HOME/.local/share/fonts"

# Python venv
echo -e "${GREEN}==> Setting up Python environment...${NC}"

VENV_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
REQ_FILE="$SCRIPT_DIR/../sdata/uv/requirements.txt"

if [[ ! -d "$VENV_PATH" ]]; then
    mkdir -p "$(dirname "$VENV_PATH")"
    python3 -m venv "$VENV_PATH"
fi

source "$VENV_PATH/bin/activate"
if [[ -f "$REQ_FILE" ]]; then
    pip install --upgrade pip
    pip install -r "$REQ_FILE"
fi
deactivate

# kde-material-you-colors
if ! pipx list | grep -q "kde-material-you-colors"; then
    pipx install kde-material-you-colors || true
fi

echo
echo -e "${GREEN}✅ Installation complete!${NC}"
