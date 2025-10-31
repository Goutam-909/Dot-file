#!/usr/bin/env bash
# Toggle clipboard with cliphist + rofi
theme="$HOME/.config/rofi/themes/clipboard.rasi"
pidfile="/tmp/rofi_clipboard.pid"

# Check if rofi is already running (real rofi process)
if pgrep -x rofi >/dev/null; then
  pkill -x rofi
  [[ -f $pidfile ]] && rm "$pidfile"
  exit 0
fi

# Check dependencies
if ! command -v cliphist &>/dev/null || ! command -v wl-copy &>/dev/null; then
  notify-send " Missing cliphist or wl-copy" -u critical
  exit 1
fi

# Function to show help message
show_help() {
  notify-send " Clipboard Manager" \
    "Enter: Copy to clipboard\nCtrl+Delete: Delete entry\nAlt+Delete: Wipe all clipboard data" \
    -t 3000
}

# Launch rofi with custom keybindings and get selection
selection=$(cliphist list | rofi -dmenu \
  -theme "$theme" \
  -kb-custom-1 "ctrl+Delete" \
  -kb-custom-2 "alt+Delete" \
  -kb-custom-3 "F1")

# Get the exit code to determine which key was pressed
exit_code=$?

case $exit_code in
  0)  # Normal selection (Enter pressed)
    if [[ -n "$selection" ]]; then
      echo "$selection" | cliphist decode | wl-copy
      notify-send "  Copied to clipboard" "$selection" -t 2000
    fi
    ;;
  10) # Custom key 1 (Ctrl+Delete) - Delete entry
    if [[ -n "$selection" ]]; then
      # Delete the specific entry from cliphist
      echo "$selection" | cliphist delete
      notify-send "  Deleted from clipboard history" "$selection" -t 2000
    else
      notify-send " No entry selected to delete" -u normal -t 2000
    fi
    ;;
  11) # Custom key 2 (Alt+Delete) - Wipe all
    cliphist wipe
    notify-send "  Clipboard history wiped" "All entries deleted" -t 2000
    ;;
  12) # Custom key 3 (F1) - Help
    show_help
    ;;
  1)  # Escape pressed or rofi cancelled
    exit 0
    ;;
  *)  # Other exit codes
    exit 0
    ;;
esac
