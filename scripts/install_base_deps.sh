#!/usr/bin/env bash
# ===============================================
#  Install Base Dependencies
# ===============================================

set -e

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

# Cleanup lock on interrupt
trap 'sudo rm -f /var/lib/pacman/db.lck 2>/dev/null; exit 130' INT TERM

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Installing Base Dependencies${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

# Update system
echo -e "${GREEN}==> Updating system...${NC}"
sudo pacman -Syu

# GTK/GNOME libraries
echo -e "${GREEN}==> Installing GTK libraries...${NC}"

BASE_GTK_DEPS=(
    gtk3 gtk4 glib2 glib-networking gobject-introspection
    adwaita-icon-theme hicolor-icon-theme gtk-engine-murrine sassc
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-kde
    xdg-user-dirs xdg-utils gsettings-desktop-schemas dconf dconf-editor
    cairo pango librsvg gdk-pixbuf2
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gstreamer-vaapi
    gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc
    polkit polkit-kde-agent gnome-keyring libsecret
    networkmanager network-manager-applet
)

for pkg in "${BASE_GTK_DEPS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        sudo pacman -S --needed --noconfirm "$pkg" || true
    fi
done

# Qt dependencies
echo -e "${GREEN}==> Installing Qt dependencies...${NC}"

QT_DEPS=(
    qt5-base qt5-tools qt5-wayland
    qt6-base qt6-declarative qt6-imageformats qt6-multimedia 
    qt6-positioning qt6-quicktimeline qt6-sensors qt6-svg 
    qt6-tools qt6-translations qt6-wayland qt6-5compat
)

for pkg in "${QT_DEPS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        sudo pacman -S --needed --noconfirm "$pkg" || true
    fi
done

# Wayland essentials
echo -e "${GREEN}==> Installing Wayland...${NC}"

WAYLAND_DEPS=(
    wayland wayland-protocols xorg-xwayland
    wl-clipboard wf-recorder xdg-desktop-portal-hyprland
)

for pkg in "${WAYLAND_DEPS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        sudo pacman -S --needed --noconfirm "$pkg" || true
    fi
done

# System utilities
echo -e "${GREEN}==> Installing system utilities...${NC}"

SYSTEM_UTILS=(
    base-devel git cmake meson ninja
    jq yq python python-pip python-pipx uv unzip
)

for pkg in "${SYSTEM_UTILS[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        sudo pacman -S --needed --noconfirm "$pkg" || true
    fi
done

echo -e "${GREEN}✅ Base dependencies installed!${NC}"
