#!/usr/bin/env bash
# ===============================================
#  GNOME Cleanup Script
#  Removes default GNOME apps (keeps dependencies)
# ===============================================

set -e

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}  GNOME Cleanup${NC}"
echo -e "${YELLOW}=======================================${NC}"
echo
echo "This will remove default GNOME applications"
echo "while keeping essential libraries and dependencies."
echo

read -rp "Continue with cleanup? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo -e "${GREEN}==> Removing GNOME default applications...${NC}"

# List of GNOME apps to remove (not their dependencies)
GNOME_APPS_TO_REMOVE=(
    # GNOME Core Apps (bloat)
    gnome-contacts
    gnome-weather
    gnome-maps
    gnome-music
    gnome-photos
    totem
    gnome-characters
    gnome-connections
    
    # System utilities (we have alternatives)
    baobab
    gnome-system-monitor
    gnome-logs
    gnome-disk-utility
    
    # Help and tour
    gnome-tour
    yelp
    gnome-user-docs
    
    # Web and office
    simple-scan
    epiphany
    
    # Calendar and software
    gnome-calendar
    gnome-software
    
    # Text editor (using alternatives)
    gnome-text-editor
    
    # Parental controls
    malcontent
    
    # System monitor replacement
    htop
)

# Remove packages
for pkg in "${GNOME_APPS_TO_REMOVE[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        echo -e "${YELLOW}Removing $pkg...${NC}"
        sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null || \
            sudo pacman -Rn --noconfirm "$pkg" 2>/dev/null || \
            echo -e "${RED}Failed to remove $pkg (might be dependency)${NC}"
    else
        echo -e "${GREEN}✓ $pkg not installed${NC}"
    fi
done

# Clean orphaned packages
echo -e "${GREEN}==> Cleaning orphaned packages...${NC}"
orphans=$(pacman -Qdtq 2>/dev/null || true)
if [[ -n "$orphans" ]]; then
    echo "$orphans" | sudo pacman -Rns --noconfirm - || true
    echo -e "${GREEN}✅ Orphaned packages removed${NC}"
else
    echo -e "${GREEN}✓ No orphaned packages found${NC}"
fi

# Clear package cache (optional)
read -rp "Clear package cache to save space? (y/n): " clear_cache
if [[ "$clear_cache" =~ ^[Yy]$ ]]; then
    sudo pacman -Sc --noconfirm
    echo -e "${GREEN}✅ Package cache cleared${NC}"
fi

echo
echo -e "${GREEN}✅ GNOME cleanup complete!${NC}"
echo -e "${YELLOW}Essential GNOME libraries retained for GTK app compatibility${NC}"
