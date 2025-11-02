#!/usr/bin/env bash
# ===============================================
#  GNOME Cleanup
# ===============================================

set -e

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'

# Cleanup lock on interrupt
trap 'sudo rm -f /var/lib/pacman/db.lck 2>/dev/null; exit 130' INT TERM

echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}  GNOME Cleanup${NC}"
echo -e "${YELLOW}=======================================${NC}"
echo

read -rp "Remove GNOME default apps? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    exit 0
fi

GNOME_APPS=(
    gnome-contacts gnome-weather gnome-maps gnome-music gnome-photos
    totem gnome-characters gnome-connections baobab gnome-system-monitor
    gnome-logs gnome-disk-utility gnome-tour yelp gnome-user-docs
    simple-scan epiphany gnome-calendar gnome-software gnome-text-editor
    malcontent htop
)

for pkg in "${GNOME_APPS[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        sudo pacman -Rns "$pkg" 2>/dev/null || sudo pacman -Rn "$pkg" 2>/dev/null || true
    fi
done

# Clean orphans
orphans=$(pacman -Qdtq 2>/dev/null || true)
if [[ -n "$orphans" ]]; then
    echo "$orphans" | sudo pacman -Rns - 2>/dev/null || true
fi

# Clear cache
read -rp "Clear package cache? (y/N): " clear_cache
if [[ "$clear_cache" =~ ^[Yy]$ ]]; then
    sudo pacman -Sc
fi

echo -e "${GREEN}✅ Cleanup complete!${NC}"
