#!/bin/bash

# Run hyprlock (this blocks until user unlocks)
hyprlock

# After unlock, send notification
sleep 2 && source /home/goutam01/.cache/wal/colors.sh && notify-send "System" "Unlocked! Hey $USER" -i $wallpaper
