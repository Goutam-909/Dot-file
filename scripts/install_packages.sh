#!/usr/bin/env bash
# ===============================================
#  Complete Hyprland Setup Installer
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; BLUE='\033[1;34m'; NC='\033[0m'

# Cleanup lock on interrupt
trap 'sudo rm -f /var/lib/pacman/db.lck 2>/dev/null; exit 130' INT TERM

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Hyprland Complete Setup Installer${NC}"
echo -e "${GREEN}============================================${NC}"
echo

# ===============================================
#  Helper Functions
# ===============================================

# Get list of missing pacman packages
get_missing_pkgs() {
    local missing=()
    for pkg in "$@"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    echo "${missing[@]}"
}

# Get list of missing AUR packages
get_missing_aur_pkgs() {
    local missing=()
    for pkg in "$@"; do
        if ! pacman -Q "$pkg" &>/dev/null && ! yay -Q "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    echo "${missing[@]}"
}

# ===============================================
#  System Update
# ===============================================

echo -e "${GREEN}==> Updating system...${NC}"
sudo pacman -Syu --noconfirm

# ===============================================
#  Install yay AUR Helper
# ===============================================

if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}==> Installing yay AUR helper...${NC}"
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd - >/dev/null
    rm -rf /tmp/yay
    echo -e "${GREEN}✅ yay installed${NC}"
fi

# ===============================================
#  GTK/GNOME Libraries
# ===============================================

echo -e "${GREEN}==> Installing GTK libraries...${NC}"

BASE_GTK_DEPS=(
    gtk3 gtk4 glib2 glib-networking gobject-introspection
    adwaita-icon-theme hicolor-icon-theme sassc
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-kde
    xdg-user-dirs xdg-utils gsettings-desktop-schemas dconf dconf-editor
    cairo pango librsvg gdk-pixbuf2
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gstreamer-vaapi
    gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc
    polkit polkit-kde-agent gnome-keyring libsecret
    networkmanager network-manager-applet bluedevil cava slurp power-profiles-daemon
)

MISSING_GTK=($(get_missing_pkgs "${BASE_GTK_DEPS[@]}"))
if [ ${#MISSING_GTK[@]} -gt 0 ]; then
    sudo pacman -S --needed --noconfirm "${MISSING_GTK[@]}"
fi

# ===============================================
#  Qt Dependencies
# ===============================================

echo -e "${GREEN}==> Installing Qt dependencies...${NC}"

QT_DEPS=(
    qt5-base qt5-tools qt5-wayland
    qt6-base qt6-declarative qt6-imageformats qt6-multimedia 
    qt6-positioning qt6-quicktimeline qt6-sensors qt6-svg 
    qt6-tools qt6-translations qt6-wayland qt6-5compat
)

MISSING_QT=($(get_missing_pkgs "${QT_DEPS[@]}"))
if [ ${#MISSING_QT[@]} -gt 0 ]; then
    sudo pacman -S --needed --noconfirm "${MISSING_QT[@]}"
fi

# ===============================================
#  Wayland Essentials
# ===============================================

echo -e "${GREEN}==> Installing Wayland...${NC}"

WAYLAND_DEPS=(
    wayland wayland-protocols xorg-xwayland
    wl-clipboard wf-recorder xdg-desktop-portal-hyprland
)

MISSING_WAYLAND=($(get_missing_pkgs "${WAYLAND_DEPS[@]}"))
if [ ${#MISSING_WAYLAND[@]} -gt 0 ]; then
    sudo pacman -S --needed --noconfirm "${MISSING_WAYLAND[@]}"
fi

# ===============================================
#  System Utilities
# ===============================================

echo -e "${GREEN}==> Installing system utilities...${NC}"

SYSTEM_UTILS=(
    base-devel git cmake meson ninja
    jq yq python python-pip python-pipx uv unzip bc
)

MISSING_UTILS=($(get_missing_pkgs "${SYSTEM_UTILS[@]}"))
if [ ${#MISSING_UTILS[@]} -gt 0 ]; then
    sudo pacman -S --needed --noconfirm "${MISSING_UTILS[@]}"
fi

# ===============================================
#  Hyprland Core Packages
# ===============================================

echo -e "${GREEN}==> Installing Hyprland and graphics drivers...${NC}"

HYPRLAND_CORE=(
    hyprland hypridle hyprlock hyprutils hyprsunset hyprpaper
    mesa vulkan-tools
    intel-media-driver libva-intel-driver vulkan-intel
    libva-mesa-driver vulkan-radeon xf86-video-amdgpu xf86-video-ati
    vulkan-nouveau xf86-video-nouveau
    xorg-server xorg-xinit
)

MISSING_HYPRLAND=($(get_missing_pkgs "${HYPRLAND_CORE[@]}"))
if [ ${#MISSING_HYPRLAND[@]} -gt 0 ]; then
    sudo pacman -S --needed --noconfirm "${MISSING_HYPRLAND[@]}"
fi

# ===============================================
#  SDDM Display Manager
# ===============================================

echo -e "${GREEN}==> Installing SDDM...${NC}"
if ! pacman -Q sddm &>/dev/null; then
    sudo pacman -S --needed --noconfirm sddm
fi

if ! systemctl is-enabled sddm.service &>/dev/null; then
    sudo systemctl enable sddm.service
    echo -e "${BLUE}SDDM enabled${NC}"
fi

# ===============================================
#  Terminal & Essential Tools
# ===============================================

echo -e "${GREEN}==> Installing terminal and essential tools...${NC}"

ESSENTIAL_TOOLS=(
    kitty
    timeshift brightnessctl ddcutil
    dolphin kdegraphics-thumbnailers ffmpegthumbs ffmpegthumbnailer
    rofi-wayland kdialog ark starship fastfetch
    python-pywal python-pillow python-opencv
    nm-connection-editor plasma-nm
    upower pipewire pipewire-pulse wireplumber
    cliphist xournalpp breeze syntax-highlighting
)

MISSING_ESSENTIAL=($(get_missing_pkgs "${ESSENTIAL_TOOLS[@]}"))
if [ ${#MISSING_ESSENTIAL[@]} -gt 0 ]; then
    sudo pacman -S --needed --noconfirm "${MISSING_ESSENTIAL[@]}"
fi

# ===============================================
#  Flatpak (Optional)
# ===============================================

echo
read -rp "Install Flatpak and Flathub? (y/N): " install_flatpak
if [[ "$install_flatpak" =~ ^[Yy]$ ]]; then
    if ! pacman -Q flatpak &>/dev/null; then
        sudo pacman -S --needed --noconfirm flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    echo -e "${GREEN}✅ Flatpak configured${NC}"
fi

# ===============================================
#  AUR Packages
# ===============================================

echo -e "${GREEN}==> Installing AUR packages...${NC}"

AUR_PKGS=(
    quickshell wlogout python-materialyoucolor matugen-bin
    adw-gtk-theme-git breeze-plus mpvpaper
)

MISSING_AUR=($(get_missing_aur_pkgs "${AUR_PKGS[@]}"))
if [ ${#MISSING_AUR[@]} -gt 0 ]; then
    yay -S --noconfirm "${MISSING_AUR[@]}"
fi

# ===============================================
#  JetBrains Mono Nerd Font
# ===============================================

echo -e "${GREEN}==> Installing JetBrains Mono Nerd Font...${NC}"

JETBRAINS_FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
if [[ ! -d "$JETBRAINS_FONT_DIR" ]] || [[ $(ls -A "$JETBRAINS_FONT_DIR" 2>/dev/null | wc -l) -eq 0 ]]; then
    mkdir -p "$JETBRAINS_FONT_DIR"
    cd "$JETBRAINS_FONT_DIR"
    curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o JetBrainsMono.zip
    unzip -oq JetBrainsMono.zip
    rm JetBrainsMono.zip
    cd - >/dev/null
    echo -e "${GREEN}✅ JetBrains Mono installed${NC}"
fi

# ===============================================
#  Material Symbols Fonts
# ===============================================

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
    echo -e "${GREEN}✅ Material Symbols installed${NC}"
fi

# Rebuild font cache
fc-cache -f "$HOME/.local/share/fonts"

# ===============================================
#  Python Virtual Environment
# ===============================================

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

# Install kde-material-you-colors
if ! pipx list 2>/dev/null | grep -q "kde-material-you-colors"; then
    pipx install kde-material-you-colors || true
fi

# ===============================================
#  Complete
# ===============================================

echo
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo -e "  • Reboot your system"
echo -e "  • SDDM will start automatically"
echo -e "  • Select Hyprland from the session menu"
echo
