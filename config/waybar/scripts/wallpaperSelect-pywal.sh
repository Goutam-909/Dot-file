#!/usr/bin/env bash
# Wallpaper picker with pywal, swww, and swaync integration

wallpaperDir="$HOME/Pictures/wallpapers"
themesDir="$HOME/.config/rofi/themes"
currentWallpaper="$HOME/.cache/current_wallpaper"
rofiWallpaper="$HOME/.current_wallpaper"
randomIcon="$wallpaperDir/random.png"  # Visual-only icon

# Transition animation config
FPS=60
TYPE="any"
DURATION=3
BEZIER="0.4,0.2,0.4,1.0"
SWWW_PARAMS="--transition-fps ${FPS} --transition-type ${TYPE} --transition-duration ${DURATION} --transition-bezier ${BEZIER}"

# Check dependencies
if ! command -v wal &>/dev/null; then
  echo "❌ pywal is not installed."
  exit 1
fi

# Prevent reopening if already running
if pidof rofi >/dev/null; then
  pkill rofi
  exit 0
fi

# Get wallpaper list (exclude random.png)
PICS=($(find -L "$wallpaperDir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' \) ! -name "random.png" | sort))

# Random wallpaper
randomNumber=$(( ($(date +%s) + RANDOM) + $$ ))
randomPicture="${PICS[$(( randomNumber % ${#PICS[@]} ))]}"

# Rofi launcher
rofiCommand="rofi -show -dmenu -theme ${themesDir}/wallpaper-select.rasi"

# Set wallpaper + apply pywal
executeCommand() {
  if command -v swww &>/dev/null; then
    swww img "$1" ${SWWW_PARAMS}
  elif command -v swaybg &>/dev/null; then
    swaybg -i "$1" &
  else
    echo "❌ Neither swww nor swaybg is installed."
    exit 1
  fi

  ln -sf "$1" "$currentWallpaper"
  ln -sf "$1" "$rofiWallpaper"
  wal -i "$1" -n -q
  echo "🎨 Wallpaper set: $1"
}

# Build the menu
menu() {
  # Random visual icon tile
  printf "Random\x00icon\x1f${randomIcon}\n"
  for pic in "${PICS[@]}"; do
    [[ "$pic" == *.gif ]] && continue
    name="$(basename "${pic}" | cut -d. -f1)"
    printf "${name}\x00icon\x1f${pic}\n"
  done
}

# Main logic
main() {
  choice=$(menu | ${rofiCommand})
  [[ -z $choice ]] && exit 0

  if [[ "$choice" == "Random" ]]; then
    executeCommand "${randomPicture}"
  else
    for file in "${PICS[@]}"; do
      name="$(basename "${file}" | cut -d. -f1)"
      if [[ "$choice" == "$name" ]]; then
        executeCommand "$file"
        break
      fi
    done
  fi

  # Restart swaync cleanly
  if pgrep -x "swaync" >/dev/null; then
    killall -q swaync
    killall waybar
    sleep 0.5
    swaync &
    waybar &
  fi
}

# Start swww if needed
if command -v swww &>/dev/null; then
  swww query || swww init
fi

main
