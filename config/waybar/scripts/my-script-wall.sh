#!/usr/bin/env bash
# Wallpaper picker with swww and mpvpaper
# Separate wallpaper setting and restoration functionality

wallpaperDir="$HOME/Pictures/wallpapers"
themesDir="$HOME/.config/rofi/themes"
currentWallpaper="$HOME/.cache/current_wallpaper"
rofiWallpaper="$HOME/.current_wallpaper"
randomIcon="$wallpaperDir/random.png"  # Visual-only icon
videoIcon="$HOME/Pictures/wallpapers/videoicon.png"  # Video selection icon
screenshotDir="$HOME/.config/hypr/screenshot"
currentVideoWallpaper="$HOME/.cache/current_video_wallpaper"
wallpaperState="$HOME/.cache/wallpaper_state"  # Track current wallpaper type

# Create screenshot directory if it doesn't exist
mkdir -p "$screenshotDir"

# Transition animation config
FPS=60
TYPE="any"
DURATION=3
BEZIER="0.4,0.2,0.4,1.0"
SWWW_PARAMS="--transition-fps ${FPS} --transition-type ${TYPE} --transition-duration ${DURATION} --transition-bezier ${BEZIER}"

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --check    Restore wallpaper from saved state"
    echo "  --help     Show this help message"
    echo ""
    echo "Without options: Open wallpaper selector"
}

# Function to save wallpaper state
saveWallpaperState() {
    local type="$1"
    local path="$2"
    echo "TYPE=$type" > "$wallpaperState"
    echo "PATH=$path" >> "$wallpaperState"
    echo "TIMESTAMP=$(date +%s)" >> "$wallpaperState"
    echo "✅ Wallpaper state saved: $type - $path"
}

# Function to load wallpaper state
loadWallpaperState() {
    if [[ -f "$wallpaperState" ]]; then
        source "$wallpaperState"
        return 0
    else
        return 1
    fi
}

# Function to manage daemons based on wallpaper type
manageDaemons() {
    local mode="$1"  # "video" or "image"

    if [[ "$mode" == "video" ]]; then
        # For video wallpapers, stop swww-daemon
        if /usr/bin/pgrep -x "swww-daemon" >/dev/null; then
            echo "🔄 Stopping swww-daemon for video wallpaper..."
            killall -q swww-daemon
            sleep 1
        fi
        if /usr/bin/pgrep -x "swww" >/dev/null; then
            killall -q swww
            sleep 0.5
        fi

    elif [[ "$mode" == "image" ]]; then
        # For image wallpapers, stop mpvpaper and start swww-daemon
        if /usr/bin/pgrep -x "mpvpaper" >/dev/null; then
            echo "🔄 Stopping mpvpaper for image wallpaper..."
            killall -q mpvpaper
            sleep 1
        fi

        # Start swww-daemon if available and not running
        if command -v swww-daemon &>/dev/null; then
            if ! /usr/bin/pgrep -x "swww-daemon" >/dev/null; then
                echo "🔥 Starting swww-daemon..."
                swww-daemon &
                sleep 2
            fi
        fi
    fi
}

# Check basic dependencies
if ! command -v kdialog &>/dev/null; then
    echo "⚠️ kdialog is not installed."
    exit 1
fi

# Prevent reopening if already running (only for interactive mode)
if [[ $# -eq 0 ]] && pidof rofi >/dev/null; then
    pkill rofi
    exit 0
fi

# Get wallpaper list (exclude random.png and videoicon.png)
PICS=($(find -L "$wallpaperDir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' \) ! -name "random.png" ! -name "videoicon.png" | sort))

# Random wallpaper selection
randomNumber=$(( ($(date +%s) + RANDOM) + $$ ))
randomPicture="${PICS[$(( randomNumber % ${#PICS[@]} ))]}"

# Rofi launcher command
rofiCommand="rofi -show -dmenu -theme ${themesDir}/wallpaper-select.rasi"

# Take screenshot from video for reference
takeVideoScreenshot() {
    local video_path="$1"
    local video_name="$(/usr/bin/basename "${video_path%.*}")"
    local screenshot_name="${video_name}.png"
    local screenshot_path="$screenshotDir/$screenshot_name"

    # Check if screenshot already exists
    if [[ -f "$screenshot_path" ]]; then
        echo "📷 Using existing screenshot: $screenshot_path"
        ln -sf "$screenshot_path" "$currentWallpaper"
        ln -sf "$screenshot_path" "$rofiWallpaper"
        return 0
    fi

    echo "📸 Taking screenshot for reference..."

    # Use ffmpeg to take screenshot
    if command -v ffmpeg &>/dev/null; then
        # Get video duration and take screenshot from 10% into video
        duration=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video_path" 2>/dev/null || echo "30")
        screenshot_time=$(echo "$duration * 0.1" | bc -l 2>/dev/null || echo "3")

        if (( $(echo "$screenshot_time > 30" | bc -l 2>/dev/null || echo "0") )); then
            screenshot_time="10"
        fi

        echo "🎬 Taking screenshot at ${screenshot_time}s from video..."
        ffmpeg -i "$video_path" -ss "$screenshot_time" -vframes 1 -q:v 2 "$screenshot_path" -y &>/dev/null

        if [[ -f "$screenshot_path" && -s "$screenshot_path" ]]; then
            ln -sf "$screenshot_path" "$currentWallpaper"
            ln -sf "$screenshot_path" "$rofiWallpaper"
            echo "✅ Screenshot saved: $screenshot_path"
            return 0
        fi
    fi

    # Fallback: try different time
    if command -v ffmpeg &>/dev/null; then
        echo "🔄 Trying fallback screenshot at 5s..."
        ffmpeg -i "$video_path" -ss 5 -vframes 1 -q:v 2 "$screenshot_path" -y &>/dev/null
        if [[ -f "$screenshot_path" && -s "$screenshot_path" ]]; then
            ln -sf "$screenshot_path" "$currentWallpaper"
            ln -sf "$screenshot_path" "$rofiWallpaper"
            echo "✅ Fallback screenshot saved"
            return 0
        fi
    fi

    # Create placeholder if all else fails
    if command -v convert &>/dev/null; then
        convert -size 1920x1080 xc:#1e1e2e "$screenshot_path" 2>/dev/null
        if [[ -f "$screenshot_path" ]]; then
            ln -sf "$screenshot_path" "$currentWallpaper"
            ln -sf "$screenshot_path" "$rofiWallpaper"
            echo "✅ Placeholder image created"
            return 0
        fi
    fi

    echo "⚠️ Screenshot creation failed"
    return 1
}

# Set video wallpaper
setVideoWallpaper() {
    local video_path="$1"

    if ! command -v mpvpaper &>/dev/null; then
        echo "⚠️ mpvpaper is not installed."
        return 1
    fi

    echo "🎬 Setting video wallpaper: $(basename "$video_path")"

    # Manage daemons for video mode
    manageDaemons "video"

    # Store video wallpaper path
    echo "$video_path" > "$currentVideoWallpaper"

    # Start mpvpaper
    mpvpaper -o "no-audio --loop-file=inf" '*' "$video_path" &
    sleep 1

    # Take screenshot for reference
    takeVideoScreenshot "$video_path"

    # Save state
    saveWallpaperState "video" "$video_path"

    echo "✅ Video wallpaper set successfully"
}

# Set image wallpaper
setImageWallpaper() {
    local image_path="$1"

    echo "🖼️ Setting image wallpaper: $(basename "$image_path")"

    # Manage daemons for image mode
    manageDaemons "image"

    # Clear video wallpaper reference
    [[ -f "$currentVideoWallpaper" ]] && rm -f "$currentVideoWallpaper"

    # Set wallpaper using swww or swaybg
    if command -v swww &>/dev/null; then
        # Wait for swww-daemon to be ready
        local attempts=0
        while ! swww query &>/dev/null && [[ $attempts -lt 10 ]]; do
            sleep 0.5
            ((attempts++))
        done

        if swww query &>/dev/null; then
            swww img "$image_path" ${SWWW_PARAMS}
        else
            echo "⚠️ swww-daemon not responding, falling back to swaybg"
            if command -v swaybg &>/dev/null; then
                swaybg -i "$image_path" &
            fi
        fi
    elif command -v swaybg &>/dev/null; then
        swaybg -i "$image_path" &
    else
        echo "⚠️ Neither swww nor swaybg is installed."
        return 1
    fi

    # Update wallpaper references
    ln -sf "$image_path" "$currentWallpaper"
    ln -sf "$image_path" "$rofiWallpaper"

    # Save state
    saveWallpaperState "image" "$image_path"

    echo "✅ Image wallpaper set successfully"
}

# Video selection dialog
selectVideoWallpaper() {
    echo "🎬 Opening video selection dialog..."

    local video_path
    video_path=$(kdialog --getopenfilename "$HOME" "Video Files (*.mp4 *.mkv *.avi *.mov *.webm *.flv *.wmv *.m4v)")

    if [[ -n "$video_path" && -f "$video_path" ]]; then
        setVideoWallpaper "$video_path"
    else
        echo "❌ No video selected or file doesn't exist"
    fi
}

# Restore wallpaper from saved state
restoreWallpaper() {
    echo "🔍 Restoring wallpaper from saved state..."

    # Load saved state
    if ! loadWallpaperState; then
        echo "❌ No wallpaper state file found at: $wallpaperState"
        return 1
    fi

    echo "📋 Found saved state: TYPE=$TYPE, PATH=$PATH"

    # Validate saved path exists
    if [[ ! -f "$PATH" ]]; then
        echo "❌ Saved wallpaper file not found: $PATH"
        return 1
    fi

    # Restore based on type
    if [[ "$TYPE" == "video" ]]; then
        echo "🎬 Restoring video wallpaper..."

        # Kill swww-daemon if running
        if pgrep -x swww-daemon >/dev/null; then
            echo "🔴 Stopping swww-daemon..."
            pkill -9 swww-daemon
        fi

        # Kill old mpvpaper instances
        if pgrep -x mpvpaper >/dev/null; then
            echo "🔴 Killing old mpvpaper..."
            pkill -9 mpvpaper
        fi

        # Manage daemons for video
        manageDaemons "video"

        # Store video path
        echo "$PATH" > "$currentVideoWallpaper"

        # Start mpvpaper
        /usr/bin/mpvpaper -o "no-audio --loop-file=inf" '*' "$PATH" &
        /usr/bin/sleep 1

        # Restore screenshot reference if it exists
        local video_name="$(/usr/bin/basename "${PATH%.*}")"
        local screenshot_path="$screenshotDir/${video_name}.png"
        if [[ -f "$screenshot_path" ]]; then
            /usr/bin/ln -sf "$screenshot_path" "$currentWallpaper"
            /usr/bin/ln -sf "$screenshot_path" "$rofiWallpaper"
        else
            # Take new screenshot
            takeVideoScreenshot "$PATH"
        fi

        echo "✅ Video wallpaper restored: $(/usr/bin/basename "$PATH")"

    elif [[ "$TYPE" == "image" ]]; then
        echo "🖼️ Restoring image wallpaper..."

        # Kill mpvpaper if running
        if /usr/bin/pgrep -x mpvpaper >/dev/null; then
            echo "🔴 Killing old mpvpaper..."
            pkill -9 mpvpaper
        fi

        # Ensure swww-daemon is running
        if ! /usr/bin/pgrep -x swww-daemon >/dev/null; then
              echo "▶️ Starting swww-daemon..."
              /usr/bin/swww-daemon &
              /usr/bin/sleep 1
        fi

        # Manage daemons for image
        manageDaemons "image"

        # Clear video wallpaper reference
        [[ -f "$currentVideoWallpaper" ]] && rm -f "$currentVideoWallpaper"

        /usr/bin/swww img "$PATH" ${SWWW_PARAMS}

        # Update references
        /usr/bin/ln -sf "$PATH" "$currentWallpaper"
        /usr/bin/ln -sf "$PATH" "$rofiWallpaper"

        echo "✅ Image wallpaper restored: $(/usr/bin/basename "$PATH")"

    else
        echo "❌ Unknown wallpaper type in state file: $TYPE"
        return 1
    fi

    echo "✅ Wallpaper restoration completed"
}

# Handle command line arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        --check)
            restoreWallpaper
            exit $?
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            usage
            exit 1
            ;;
    esac
fi

# Build the rofi menu
menu() {
    # Random wallpaper option
    printf "Random\x00icon\x1f${randomIcon}\n"

    # Video wallpaper option
    printf "Live Video\x00icon\x1f${videoIcon}\n"

    # Image wallpapers
    for pic in "${PICS[@]}"; do
        [[ "$pic" == *.gif ]] && continue
        name="$(basename "${pic}" | cut -d. -f1)"
        printf "${name}\x00icon\x1f${pic}\n"
    done
}

# Main wallpaper selection logic
main() {
    choice=$(menu | ${rofiCommand})
    [[ -z $choice ]] && exit 0

    case "$choice" in
        "Random")
            echo "🎲 Setting random wallpaper..."
            setImageWallpaper "${randomPicture}"
            ;;
        "Live Video")
            selectVideoWallpaper
            ;;
        *)
            # Find and set selected image
            for file in "${PICS[@]}"; do
                name="$(basename "${file}" | cut -d. -f1)"
                if [[ "$choice" == "$name" ]]; then
                    setImageWallpaper "$file"
                    break
                fi
            done
            ;;
    esac

    # Apply pywal colors after setting wallpaper
    if command -v wal &>/dev/null && [[ -f "$currentWallpaper" ]]; then
        echo "🎨 Applying pywal colors..."
        wal -i "$(readlink -f "$currentWallpaper")" -n -q
        matugen image "$(readlink -f "$currentWallpaper")"

        # Restart swaync and waybar for new colors
        if /usr/bin/pgrep -x "swaync" >/dev/null; then
            killall -q swaync
            sleep 0.2
            swaync &
        fi
        if /usr/bin/pgrep -x "waybar" >/dev/null; then
            killall -q waybar
            sleep 0.2
            waybar &
        fi
        # Refresh eww for new colors
        if /usr/bin/pgrep -x "eww" >/dev/null; then
            echo "🔄 Refreshing eww with new colors..."
            eww reload
        fi
    fi
}

# Run main function
main
