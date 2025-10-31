#!/usr/bin/env bash
# ===============================================
#  Install Base Dependencies (GNOME-free)
#  Essential GTK/GNOME libraries without bloat
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
echo -e "${GREEN}  Installing Base Dependencies${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

# Update system first
echo -e "${GREEN}==> Updating system...${NC}"
sudo pacman -Syu --noconfirm

# Essential GTK/GNOME dependencies (without full GNOME)
echo -e "${GREEN}==> Installing GTK and essential libraries...${NC}"

BASE_GTK_DEPS=(
    # GTK Libraries
    gtk3 gtk4 
    
    # GLib and core GNOME libraries
    glib2 glib-networking gobject-introspection
    
    # Theme engines and styling
    adwaita-icon-theme hicolor-icon-theme
    gtk-engine-murrine sassc
    
    # Desktop integration
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-kde
    xdg-user-dirs xdg-utils
    
    # GSettings backend
    gsettings-desktop-schemas
    dconf dconf-editor
    
    # Graphics and rendering
    cairo pango librsvg gdk-pixbuf2
    
    # Fonts
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji
    
    # Audio/Video codecs for GTK apps
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
    gstreamer-vaapi
    
    # File management libraries
    gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc
    
    # Authentication
    polkit polkit-kde-agent
    gnome-keyring libsecret
    
    # Network
    networkmanager network-manager-applet
)

for pkg in "${BASE_GTK_DEPS[@]}"; do
    install_if_missing "$pkg"
done

# Qt dependencies for QuickShell
echo -e "${GREEN}==> Installing Qt dependencies...${NC}"

QT_DEPS=(
    qt5-base qt5-tools qt5-wayland
    qt6-base qt6-declarative qt6-imageformats qt6-multimedia 
    qt6-positioning qt6-quicktimeline qt6-sensors qt6-svg 
    qt6-tools qt6-translations qt6-wayland qt6-5compat
)

for pkg in "${QT_DEPS[@]}"; do
    install_if_missing "$pkg"
done

# Wayland essentials
echo -e "${GREEN}==> Installing Wayland essentials...${NC}"

WAYLAND_DEPS=(
    wayland wayland-protocols
    xorg-xwayland
    wl-clipboard wf-recorder
    xdg-desktop-portal-hyprland
)

for pkg in "${WAYLAND_DEPS[@]}"; do
    install_if_missing "$pkg"
done

# System utilities
echo -e "${GREEN}==> Installing system utilities...${NC}"

SYSTEM_UTILS=(
    base-devel git
    cmake meson ninja
    jq yq
    python python-pip python-pipx
    uv
)

for pkg in "${SYSTEM_UTILS[@]}"; do
    install_if_missing "$pkg"
done

echo -e "${GREEN}✅ Base dependencies installed successfully!${NC}"
