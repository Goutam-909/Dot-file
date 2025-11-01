#!/usr/bin/env bash
# ===============================================
#  Install Base Dependencies (GNOME-free)
#  Essential GTK/GNOME libraries without bloat
# ===============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

# Error tracking
declare -a FAILED_PACKAGES=()
CTRL_C_COUNT=0
CTRL_C_TIME=0

# Trap Ctrl+C
trap 'handle_interrupt' INT

handle_interrupt() {
    local current_time=$(date +%s)
    
    # Reset counter if more than 2 seconds passed
    if [[ $((current_time - CTRL_C_TIME)) -gt 2 ]]; then
        CTRL_C_COUNT=0
    fi
    
    CTRL_C_COUNT=$((CTRL_C_COUNT + 1))
    CTRL_C_TIME=$current_time
    
    if [[ $CTRL_C_COUNT -eq 1 ]]; then
        echo -e "\n${YELLOW}⚠ Interrupt detected! Press Ctrl+C again within 2 seconds to exit.${NC}"
        return 1
    else
        echo -e "\n${RED}Double interrupt detected. Exiting...${NC}"
        exit 130
    fi
}

install_if_missing() {
    local pkg="$1"
    local max_retries=3
    local retry_count=0
    
    if pacman -Q "$pkg" &>/dev/null; then
        echo -e "${YELLOW}✓ $pkg already installed${NC}"
        return 0
    fi
    
    while [[ $retry_count -lt $max_retries ]]; do
        echo -e "${GREEN}Installing $pkg... (attempt $((retry_count + 1))/$max_retries)${NC}"
        
        if sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
            echo -e "${GREEN}✅ $pkg installed successfully${NC}"
            return 0
        fi
        
        if [[ $? -eq 130 ]] || [[ $CTRL_C_COUNT -gt 0 ]]; then
            if [[ $CTRL_C_COUNT -ge 2 ]]; then
                exit 130
            fi
            echo -e "${YELLOW}Retrying $pkg...${NC}"
            CTRL_C_COUNT=0
            retry_count=$((retry_count + 1))
            continue
        fi
        
        retry_count=$((retry_count + 1))
        if [[ $retry_count -lt $max_retries ]]; then
            echo -e "${YELLOW}Retry $retry_count/$max_retries for $pkg...${NC}"
            sleep 1
        fi
    done
    
    echo -e "${RED}✗ Failed to install $pkg after $max_retries attempts${NC}"
    FAILED_PACKAGES+=("$pkg")
    return 1
}

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Installing Base Dependencies${NC}"
echo -e "${GREEN}=======================================${NC}"
echo

# Update system first
echo -e "${GREEN}==> Updating system...${NC}"
if ! sudo pacman -Syu --noconfirm; then
    echo -e "${RED}✗ System update failed${NC}"
    FAILED_PACKAGES+=("system-update")
fi

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
    install_if_missing "$pkg" || true
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
    install_if_missing "$pkg" || true
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
    install_if_missing "$pkg" || true
done

# System utilities
echo -e "${GREEN}==> Installing system utilities...${NC}"

SYSTEM_UTILS=(
    base-devel git
    cmake meson ninja
    jq yq
    python python-pip python-pipx
    uv
    unzip  # For extracting fonts
)

for pkg in "${SYSTEM_UTILS[@]}"; do
    install_if_missing "$pkg" || true
done

# Summary
echo
if [[ ${#FAILED_PACKAGES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ Base dependencies installed successfully!${NC}"
else
    echo -e "${YELLOW}⚠ Some packages failed to install:${NC}"
    printf '  - %s\n' "${FAILED_PACKAGES[@]}"
    echo
    echo -e "${YELLOW}You can try installing failed packages manually later.${NC}"
fi