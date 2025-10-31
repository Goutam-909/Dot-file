#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
MATUGEN_DIR="$XDG_CONFIG_HOME/matugen"
terminalscheme="$SCRIPT_DIR/terminal/scheme-base.json"

# Wallpaper symlink locations
WALLPAPER_LINK_HOME="$HOME/.current_wallpaper"
WALLPAPER_LINK_CACHE="$HOME/.cache/current_wallpaper"

# Instance management
LOCK_FILE="/tmp/switchwall_${USER}.lock"
LOCK_FD=200
DEBUG_MODE=false

debug_log() {
    if [ "$DEBUG_MODE" = true ]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Instance management functions
acquire_lock() {
    local max_wait=30  # Maximum wait time in seconds
    local waited=0
    local check_interval=0.5

    # Try to acquire lock
    eval "exec $LOCK_FD>\"$LOCK_FILE\""

    while ! flock -n $LOCK_FD; do
        if [ $waited -eq 0 ]; then
            echo "[switchwall] Another instance is running, waiting for it to complete..."
        fi

        if [ $waited -ge $max_wait ]; then
            echo "[switchwall] Timeout waiting for previous instance, forcing execution..."
            # Force remove old lock
            rm -f "$LOCK_FILE"
            eval "exec $LOCK_FD>\"$LOCK_FILE\""
            flock -n $LOCK_FD || {
                echo "[switchwall] ERROR: Could not acquire lock even after timeout"
                return 1
            }
            break
        fi

        sleep $check_interval
        waited=$(bc <<< "$waited + $check_interval")
    done

    if [ $waited -gt 0 ]; then
        echo "[switchwall] Previous instance completed, proceeding..."
    fi

    debug_log "Lock acquired"
    return 0
}

release_lock() {
    flock -u $LOCK_FD 2>/dev/null
    debug_log "Lock released"
}

handle_kde_material_you_colors() {
    # Check if Qt app theming is enabled in config
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_qt_apps=$(jq -r '.appearance.wallpaperTheming.enableQtApps' "$SHELL_CONFIG_FILE")
        if [ "$enable_qt_apps" == "false" ]; then
            debug_log "Qt apps theming disabled, skipping"
            return 0
        fi
    fi

    # Map $type_flag to allowed scheme variants for kde-material-you-colors-wrapper.sh
    local kde_scheme_variant=""
    case "$type_flag" in
        scheme-content|scheme-expressive|scheme-fidelity|scheme-fruit-salad|scheme-monochrome|scheme-neutral|scheme-rainbow|scheme-tonal-spot)
            kde_scheme_variant="$type_flag"
            ;;
        *)
            kde_scheme_variant="scheme-tonal-spot" # default
            ;;
    esac

    # Get timeout from config or use default
    local kde_timeout=30
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        kde_timeout=$(jq -r '.appearance.wallpaperTheming.kdeTimeout // 30' "$SHELL_CONFIG_FILE")
    fi

    # Run kde-material-you-colors with timeout and error handling
    echo "[switchwall] Running kde-material-you-colors (timeout: ${kde_timeout}s)..."
    local kde_result=0
    local raw_out=""

    raw_out=$(timeout "${kde_timeout}s" "$XDG_CONFIG_HOME"/matugen/templates/kde/kde-material-you-colors-wrapper.sh --scheme-variant "$kde_scheme_variant" 2>&1)
    local cmd_exit=$?

    # Filter output for readability (hide DBusException unless in debug mode)
    if [ "$DEBUG_MODE" = true ]; then
        echo "$raw_out"
    else
        echo "$raw_out" | grep -v "DBusException" || true
    fi

    # Handle exit codes
    if [ $cmd_exit -eq 124 ]; then
        echo "[switchwall] kde-material-you-colors timed out after ${kde_timeout}s"
        kde_result=124
    elif [ $cmd_exit -ne 0 ]; then
        echo "[switchwall] kde-material-you-colors failed (exit code: $cmd_exit)"
        kde_result=$cmd_exit
    else
        echo "[switchwall] kde-material-you-colors completed successfully"
        kde_result=0
    fi

    return $kde_result
}

# Cleanup function to ensure proper exit
cleanup_on_exit() {
    debug_log "Cleanup triggered"
    release_lock

    # Clean up any zombie processes
    wait 2>/dev/null

    debug_log "Cleanup completed"
}

# Set trap to cleanup on script exit
trap cleanup_on_exit EXIT INT TERM

pre_process() {
    local mode_flag="$1"
    # Set GNOME color-scheme if mode_flag is dark or light
    if [[ "$mode_flag" == "dark" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    elif [[ "$mode_flag" == "light" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    fi

    if [ ! -d "$CACHE_DIR"/user/generated ]; then
        mkdir -p "$CACHE_DIR"/user/generated
    fi
}

post_process() {
    local screen_width="$1"
    local screen_height="$2"
    local wallpaper_path="$3"

    # Store PIDs of background processes
    local bg_pids=()

    # Run kde-material-you-colors in background and track its PID
    echo "[switchwall] Starting KDE Material You Colors theming..."
    handle_kde_material_you_colors &
    local kde_pid=$!
    bg_pids+=($kde_pid)

    # Wait for all background processes to complete
    echo "[switchwall] Waiting for theming processes to complete..."
    for pid in "${bg_pids[@]}"; do
        if wait "$pid" 2>/dev/null; then
            echo "[switchwall] Process $pid completed successfully"
        else
            local exit_code=$?
            echo "[switchwall] Process $pid completed with exit code: $exit_code"
        fi
    done

    echo "[switchwall] All post-processing tasks completed"
}

check_and_prompt_upscale() {
    local img="$1"
    min_width_desired="$(hyprctl monitors -j | jq '([.[].width] | max)' | xargs)" # max monitor width
    min_height_desired="$(hyprctl monitors -j | jq '([.[].height] | max)' | xargs)" # max monitor height

    if command -v identify &>/dev/null && [ -f "$img" ]; then
        local img_width img_height
        if is_video "$img"; then # Not check resolution for videos, just let em pass
            img_width=$min_width_desired
            img_height=$min_height_desired
        else
            img_width=$(identify -format "%w" "$img" 2>/dev/null)
            img_height=$(identify -format "%h" "$img" 2>/dev/null)
        fi
        if [[ "$img_width" -lt "$min_width_desired" || "$img_height" -lt "$min_height_desired" ]]; then
            action=$(notify-send "Upscale?" \
                "Image resolution (${img_width}x${img_height}) is lower than screen resolution (${min_width_desired}x${min_height_desired})" \
                -A "open_upscayl=Open Upscayl"\
                -a "Wallpaper switcher")
            if [[ "$action" == "open_upscayl" ]]; then
                if command -v flatpak run org.upscayl.Upscayl &>/dev/null; then
                    nohup flatpak run org.upscayl.Upscayl > /dev/null 2>&1 &
                else
                    action2=$(notify-send \
                        -a "Wallpaper switcher" \
                        -c "im.error" \
                        -A "install_upscayl=Install Upscayl (Arch)" \
                        "Install Upscayl?" \
                        "yay -S upscayl-bin")
                    if [[ "$action2" == "install_upscayl" ]]; then
                        kitty -1 yay -S upscayl-bin
                        if command -v upscayl &>/dev/null; then
                            nohup upscayl > /dev/null 2>&1 &
                        fi
                    fi
                fi
            fi
        fi
    fi
}

CUSTOM_DIR="$XDG_CONFIG_HOME/hypr/custom"
RESTORE_SCRIPT_DIR="$CUSTOM_DIR/scripts"
RESTORE_SCRIPT="$RESTORE_SCRIPT_DIR/__restore_video_wallpaper.sh"
THUMBNAIL_DIR="$RESTORE_SCRIPT_DIR/mpvpaper_thumbnails"
VIDEO_OPTS="no-audio loop hwdec=auto scale=bilinear panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 video-align-x=0.5 video-align-y=0.5 load-scripts=no"

is_video() {
    local extension="${1##*.}"
    [[ "$extension" == "mp4" || "$extension" == "webm" || "$extension" == "mkv" || "$extension" == "avi" || "$extension" == "mov" ]] && return 0 || return 1
}

kill_existing_mpvpaper() {
    pkill -f -9 mpvpaper || true
}

create_restore_script() {
    local video_path=$1
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# Generated by switchwall.sh - Don't modify it by yourself.
# Time: $(date)

pkill -f -9 mpvpaper

for monitor in \$(hyprctl monitors -j | jq -r '.[] | .name'); do
    setsid mpvpaper -o "$VIDEO_OPTS" "\$monitor" "$video_path" >/dev/null 2>&1 &
    disown
    sleep 0.1
done
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
    chmod +x "$RESTORE_SCRIPT"
}

remove_restore() {
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# The content of this script will be generated by switchwall.sh - Don't modify it by yourself.
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
}

set_wallpaper_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_thumbnail_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.thumbnailPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

create_wallpaper_symlinks() {
    local target_path="$1"

    # Create symlink in home directory
    if [ -L "$WALLPAPER_LINK_HOME" ] || [ -f "$WALLPAPER_LINK_HOME" ]; then
        rm -f "$WALLPAPER_LINK_HOME"
    fi
    ln -sf "$target_path" "$WALLPAPER_LINK_HOME"

    # Create symlink in cache directory
    mkdir -p "$(dirname "$WALLPAPER_LINK_CACHE")"
    if [ -L "$WALLPAPER_LINK_CACHE" ] || [ -f "$WALLPAPER_LINK_CACHE" ]; then
        rm -f "$WALLPAPER_LINK_CACHE"
    fi
    ln -sf "$target_path" "$WALLPAPER_LINK_CACHE"

    echo "[switchwall] Created wallpaper symlinks: $target_path"
}

run_pywal() {
    local image_path="$1"
    local mode_flag="$2"

    # Check if pywal is installed
    if ! command -v wal &>/dev/null; then
        echo "[switchwall] Warning: pywal (wal) not found, skipping pywal generation"
        return
    fi

    # Check if pywal is enabled in config
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_pywal=$(jq -r '.appearance.wallpaperTheming.enablePywal // true' "$SHELL_CONFIG_FILE")
        if [ "$enable_pywal" == "false" ]; then
            echo "[switchwall] Pywal disabled in config, skipping"
            return
        fi
    fi

    # Build pywal command
    local wal_args=("-i" "$image_path" "-n")

    # Add light/dark mode flag
    if [[ "$mode_flag" == "light" ]]; then
        wal_args+=("-l")
    fi

    # Run pywal
    echo "[switchwall] Running pywal: wal ${wal_args[*]}"
    wal "${wal_args[@]}"

    # Source the colors for current shell (optional)
    if [ -f "$HOME/.cache/wal/colors.sh" ]; then
        source "$HOME/.cache/wal/colors.sh"
    fi
}

switch() {
    imgpath="$1"
    mode_flag="$2"
    type_flag="$3"
    color_flag="$4"
    color="$5"

    # Start Gemini auto-categorization if enabled
    aiStylingEnabled=$(jq -r '.background.clock.cookie.aiStyling' "$SHELL_CONFIG_FILE")
    if [[ "$aiStylingEnabled" == "true" ]]; then
        "$SCRIPT_DIR/../ai/gemini-categorize-wallpaper.sh" "$imgpath" > "$STATE_DIR/user/generated/wallpaper/category.txt" &
    fi

    read scale screenx screeny screensizey < <(hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
    cursorposx=$(hyprctl cursorpos -j | jq '.x' 2>/dev/null) || cursorposx=960
    cursorposx=$(bc <<< "scale=0; ($cursorposx - $screenx) * $scale / 1")
    cursorposy=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null) || cursorposy=540
    cursorposy=$(bc <<< "scale=0; ($cursorposy - $screeny) * $scale / 1")
    cursorposy_inverted=$((screensizey - cursorposy))

    # Variable to store the actual image for color generation (might be thumbnail for videos)
    local color_gen_image=""

    if [[ "$color_flag" == "1" ]]; then
        matugen_args=(color hex "$color")
        generate_colors_material_args=(--color "$color")
    else
        if [[ -z "$imgpath" ]]; then
            echo '[switchwall] Aborted: No image path provided'
            exit 0
        fi

        check_and_prompt_upscale "$imgpath" &
        kill_existing_mpvpaper

        if is_video "$imgpath"; then
            mkdir -p "$THUMBNAIL_DIR"

            missing_deps=()
            if ! command -v mpvpaper &> /dev/null; then
                missing_deps+=("mpvpaper")
            fi
            if ! command -v ffmpeg &> /dev/null; then
                missing_deps+=("ffmpeg")
            fi
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo "Missing deps: ${missing_deps[*]}"
                echo "Arch: sudo pacman -S ${missing_deps[*]}"
                action=$(notify-send \
                    -a "Wallpaper switcher" \
                    -c "im.error" \
                    -A "install_arch=Install (Arch)" \
                    "Can't switch to video wallpaper" \
                    "Missing dependencies: ${missing_deps[*]}")
                if [[ "$action" == "install_arch" ]]; then
                    kitty -1 sudo pacman -S "${missing_deps[*]}"
                    if command -v mpvpaper &>/dev/null && command -v ffmpeg &>/dev/null; then
                        notify-send 'Wallpaper switcher' 'Alright, try again!' -a "Wallpaper switcher"
                    fi
                fi
                exit 0
            fi

            # Set wallpaper path
            set_wallpaper_path "$imgpath"

            # Set video wallpaper
            local video_path="$imgpath"
            monitors=$(hyprctl monitors -j | jq -r '.[] | .name')
            for monitor in $monitors; do
                setsid mpvpaper -o "$VIDEO_OPTS" "$monitor" "$video_path" >/dev/null 2>&1 &
                disown
                sleep 0.1
            done

            # Extract first frame for color generation
            thumbnail="$THUMBNAIL_DIR/$(basename "$imgpath").jpg"
            ffmpeg -y -i "$imgpath" -vframes 1 "$thumbnail" 2>/dev/null

            # Set thumbnail path
            set_thumbnail_path "$thumbnail"

            if [ -f "$thumbnail" ]; then
                matugen_args=(image "$thumbnail")
                generate_colors_material_args=(--path "$thumbnail")
                color_gen_image="$thumbnail"
                create_restore_script "$video_path"

                # Create symlinks pointing to the thumbnail for videos
                create_wallpaper_symlinks "$thumbnail"
            else
                echo "Cannot create image to colorgen"
                remove_restore
                exit 1
            fi
        else
            matugen_args=(image "$imgpath")
            generate_colors_material_args=(--path "$imgpath")
            color_gen_image="$imgpath"

            # Update wallpaper path in config
            set_wallpaper_path "$imgpath"
            remove_restore

            # Create symlinks pointing to the actual image
            create_wallpaper_symlinks "$imgpath"
        fi
    fi

    # Determine mode if not set
    if [[ -z "$mode_flag" ]]; then
        current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
        if [[ "$current_mode" == "prefer-dark" ]]; then
            mode_flag="dark"
        else
            mode_flag="light"
        fi
    fi

    # enforce dark mode for terminal
    if [[ -n "$mode_flag" ]]; then
        matugen_args+=(--mode "$mode_flag")
        if [[ $(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode' "$SHELL_CONFIG_FILE") == "true" ]]; then
            generate_colors_material_args+=(--mode "dark")
        else
            generate_colors_material_args+=(--mode "$mode_flag")
        fi
    fi
    [[ -n "$type_flag" ]] && matugen_args+=(--type "$type_flag") && generate_colors_material_args+=(--scheme "$type_flag")
    generate_colors_material_args+=(--termscheme "$terminalscheme" --blend_bg_fg)
    generate_colors_material_args+=(--cache "$STATE_DIR/user/generated/color.txt")

    pre_process "$mode_flag"

    # Check if app and shell theming is enabled in config
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_apps_shell=$(jq -r '.appearance.wallpaperTheming.enableAppsAndShell' "$SHELL_CONFIG_FILE")
        if [ "$enable_apps_shell" == "false" ]; then
            echo "App and shell theming disabled, skipping matugen and color generation"
            return
        fi
    fi

    # Run pywal (if not using color flag and we have an image)
    if [[ "$color_flag" != "1" && -n "$color_gen_image" ]]; then
        run_pywal "$color_gen_image" "$mode_flag" &
    fi

    # Set harmony and related properties
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        harmony=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmony' "$SHELL_CONFIG_FILE")
        harmonize_threshold=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold' "$SHELL_CONFIG_FILE")
        term_fg_boost=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost' "$SHELL_CONFIG_FILE")
        [[ "$harmony" != "null" && -n "$harmony" ]] && generate_colors_material_args+=(--harmony "$harmony")
        [[ "$harmonize_threshold" != "null" && -n "$harmonize_threshold" ]] && generate_colors_material_args+=(--harmonize_threshold "$harmonize_threshold")
        [[ "$term_fg_boost" != "null" && -n "$term_fg_boost" ]] && generate_colors_material_args+=(--term_fg_boost "$term_fg_boost")
    fi

    timeout 3s matugen "${matugen_args[@]}"
    if [ $? -ne 0 ]; then
        echo "[switchwall] Warning: matugen failed or timed out, skipping color generation"
    fi
    timeout 3s python3 "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
        > "$STATE_DIR"/user/generated/material_colors.scss
    if [ $? -ne 0 ]; then
        echo "[switchwall] Warning: generate_colors_material.py failed or timed out"
    fi
    "$SCRIPT_DIR"/applycolor.sh

    # Pass screen width, height, and wallpaper path to post_process
    max_width_desired="$(hyprctl monitors -j | jq '([.[].width] | min)' | xargs)"
    max_height_desired="$(hyprctl monitors -j | jq '([.[].height] | min)' | xargs)"
    post_process "$max_width_desired" "$max_height_desired" "$imgpath"
}

main() {
    # Acquire lock to prevent concurrent instances
    acquire_lock || exit 1

    imgpath=""
    mode_flag=""
    type_flag=""
    color_flag=""
    color=""
    noswitch_flag=""
    kdialog_flag=""

    get_type_from_config() {
        jq -r '.appearance.palette.type' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "auto"
    }

    detect_scheme_type_from_image() {
        local img="$1"
        "$SCRIPT_DIR"/scheme_for_image.py "$img" 2>/dev/null | tr -d '\n'
    }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                mode_flag="$2"
                shift 2
                ;;
            --type)
                type_flag="$2"
                shift 2
                ;;
            --color)
                color_flag="1"
                if [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
                    color="$2"
                    shift 2
                else
                    color=$(hyprpicker --no-fancy)
                    shift
                fi
                ;;
            --image)
                imgpath="$2"
                shift 2
                ;;
            --noswitch)
                noswitch_flag="1"
                imgpath=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
                shift
                ;;
            --kdialog)
                kdialog_flag="1"
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                echo "[switchwall] Debug mode enabled"
                shift
                ;;
            *)
                # Only accept as imgpath if it's a valid file
                if [[ -z "$imgpath" && -f "$1" ]]; then
                    imgpath="$1"
                fi
                shift
                ;;
        esac
    done

    # If type_flag is not set, get it from config
    if [[ -z "$type_flag" ]]; then
        type_flag="$(get_type_from_config)"
    fi

    # Validate type_flag (allow 'auto' as well)
    allowed_types=(scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot auto)
    valid_type=0
    for t in "${allowed_types[@]}"; do
        if [[ "$type_flag" == "$t" ]]; then
            valid_type=1
            break
        fi
    done
    if [[ $valid_type -eq 0 ]]; then
        echo "[switchwall.sh] Warning: Invalid type '$type_flag', defaulting to 'auto'" >&2
        type_flag="auto"
    fi

    # Handle --kdialog flag: Open kdialog and get image path
    if [[ "$kdialog_flag" == "1" && -z "$imgpath" ]]; then
        cd "$(xdg-user-dir PICTURES)/wallpapers/showcase" 2>/dev/null || \
        cd "$(xdg-user-dir PICTURES)/wallpapers" 2>/dev/null || \
        cd "$(xdg-user-dir PICTURES)" 2>/dev/null || \
        cd "$HOME"

        imgpath="$(kdialog --getopenfilename . --title 'Choose wallpaper')"

        # Validate kdialog result
        if [[ -z "$imgpath" || ! -f "$imgpath" ]]; then
            echo "[switchwall] No wallpaper selected or file doesn't exist, aborting"
            exit 0
        fi
    fi

    # Validate imgpath exists before proceeding (skip for color mode and noswitch without imgpath)
    if [[ -n "$imgpath" && "$color_flag" != "1" && ! -f "$imgpath" ]]; then
        echo "[switchwall] Error: Image file '$imgpath' does not exist"
        exit 1
    fi

    # If no imgpath and no color_flag and no noswitch_flag, just exit
    if [[ -z "$imgpath" && -z "$color_flag" && -z "$noswitch_flag" ]]; then
        echo "[switchwall] No image, color, or noswitch flag provided. Nothing to do."
        exit 0
    fi

    # If type_flag is 'auto', detect scheme type from image (after imgpath is set)
    if [[ "$type_flag" == "auto" ]]; then
        if [[ -n "$imgpath" && -f "$imgpath" ]]; then
            detected_type="$(detect_scheme_type_from_image "$imgpath")"
            # Only use detected_type if it's valid
            valid_detected=0
            for t in "${allowed_types[@]}"; do
                if [[ "$detected_type" == "$t" && "$detected_type" != "auto" ]]; then
                    valid_detected=1
                    break
                fi
            done
            if [[ $valid_detected -eq 1 ]]; then
                type_flag="$detected_type"
            else
                echo "[switchwall] Warning: Could not auto-detect a valid scheme, defaulting to 'scheme-tonal-spot'" >&2
                type_flag="scheme-tonal-spot"
            fi
        else
            echo "[switchwall] Warning: No image to auto-detect scheme from, defaulting to 'scheme-tonal-spot'" >&2
            type_flag="scheme-tonal-spot"
        fi
    fi

    # Only call switch if we have a valid imgpath or color_flag
    if [[ -n "$imgpath" || "$color_flag" == "1" ]]; then
        switch "$imgpath" "$mode_flag" "$type_flag" "$color_flag" "$color"
    else
        echo "[switchwall] No valid wallpaper or color specified, aborting"
        exit 0
    fi
}

main "$@"
