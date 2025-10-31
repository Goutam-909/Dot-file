#!/bin/bash

# Configuration
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
TRANSITION_DURATION=3
LAST_WALLPAPER_FILE="/home/goutam01/.cache/current_wallpaper"

# Create cache directory if it doesn't exist
mkdir -p "$(dirname "$LAST_WALLPAPER_FILE")"

# Function to get all wallpapers in an array
get_all_wallpapers() {
    find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | sort
}

# Parse command line options
DIRECTION="next"  # Default direction
TRANSITION_TYPE="center"  # Default transition
CUSTOM_TRANSITION_TYPE=""

while getopts "pnd:t:" opt; do
    case $opt in
        p) DIRECTION="prev" ;;
        n) DIRECTION="next" ;;
        d) TRANSITION_DURATION="$OPTARG" ;;
        t) CUSTOM_TRANSITION_TYPE="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Set transition type based on direction unless custom transition is specified
if [ -z "$CUSTOM_TRANSITION_TYPE" ]; then
    if [ "$DIRECTION" = "next" ]; then
        TRANSITION_TYPE="center"  # Default circle expanding from center
    else
        TRANSITION_TYPE="outer"   # Reverse circle contracting from outside in
    fi
else
    TRANSITION_TYPE="$CUSTOM_TRANSITION_TYPE"
fi

# Check if swww is initialized
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww init
    sleep 1
fi

# Get all wallpapers
WALLPAPERS=($(get_all_wallpapers))
WALLPAPER_COUNT=${#WALLPAPERS[@]}

if [ $WALLPAPER_COUNT -eq 0 ]; then
    echo "{\"text\": \"󰔌\", \"tooltip\": \"No wallpapers found\"}"
    exit 1
fi

# Get current/last wallpaper index
CURRENT_INDEX=0
if [ -L "$LAST_WALLPAPER_FILE" ]; then
    # If it's a symlink, get the real path
    LAST_WALLPAPER=$(readlink -f "$LAST_WALLPAPER_FILE")
    
    # Find the index of the last wallpaper
    for i in "${!WALLPAPERS[@]}"; do
        if [ "${WALLPAPERS[$i]}" = "$LAST_WALLPAPER" ]; then
            CURRENT_INDEX=$i
            break
        fi
    done
    
    # Calculate next/previous index (cycle around)
    if [ "$DIRECTION" = "next" ]; then
        CURRENT_INDEX=$(( (CURRENT_INDEX + 1) % WALLPAPER_COUNT ))
    else  # previous
        CURRENT_INDEX=$(( (CURRENT_INDEX - 1 + WALLPAPER_COUNT) % WALLPAPER_COUNT ))
    fi
else
    # First run, use first wallpaper
    CURRENT_INDEX=0
fi

# Set the next wallpaper
NEXT_WALLPAPER="${WALLPAPERS[$CURRENT_INDEX]}"

# Apply wallpaper with swww for transition effects
swww img "$NEXT_WALLPAPER" \
    --transition-type "$TRANSITION_TYPE" \
    --transition-duration "$TRANSITION_DURATION"

# Apply colors with pywal (without transition since swww handles that)
wal -i "$NEXT_WALLPAPER" -n

# Save the current wallpaper path for next time - use symlink like in the selection script
ln -sf "$NEXT_WALLPAPER" "$LAST_WALLPAPER_FILE"

# Restart swaync to apply new theme colors
if pgrep -x "swaync" > /dev/null; then
    killall -q swaync
    sleep 0.5  # Give it time to shut down properly
fi
swaync &  # Start swaync in the background

# Display info for waybar
WALLPAPER_NAME=$(basename "$NEXT_WALLPAPER")
echo "{\"text\": \"󰸉\", \"tooltip\": \"$WALLPAPER_NAME ($((CURRENT_INDEX+1))/$WALLPAPER_COUNT)\"}"
