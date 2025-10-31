#!/usr/bin/env bash

# Complete Theme Toggle Script for Hyprland
# Properly handles GTK3, GTK4 (libadwaita), and Qt applications

# Configuration
CONFIG_DIR="$HOME/.config"
THEME_STATE_FILE="$CONFIG_DIR/theme_state"
QT5CT_CONFIG="$CONFIG_DIR/qt5ct/qt5ct.conf"
QT6CT_CONFIG="$CONFIG_DIR/qt6ct/qt6ct.conf"
KVANTUM_CONFIG="$CONFIG_DIR/Kvantum/kvantum.kvconfig"

# Create necessary directories
create_dirs() {
    mkdir -p "$CONFIG_DIR/qt5ct"
    mkdir -p "$CONFIG_DIR/qt6ct"
    mkdir -p "$CONFIG_DIR/Kvantum"
}

# Get current theme state
get_current_theme() {
    if [[ -f "$THEME_STATE_FILE" ]]; then
        cat "$THEME_STATE_FILE"
    else
        echo "dark"
    fi
}

# Set theme state
set_theme_state() {
    echo "$1" > "$THEME_STATE_FILE"
}


# Configure Qt5CT
configure_qt5ct() {
    local mode="$1"
    local qt_style=$([ "$mode" = "dark" ] && echo "kvantum-dark" || echo "kvantum")

    cat > "$QT5CT_CONFIG" << EOF
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Adwaita
standard_dialogs=default
style=$qt_style

[Fonts]
fixed="JetBrains Mono Nerd Font,10,-1,5,50,0,0,0,0,0"
general="JetBrains Mono Nerd Font,11,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[Troubleshooting]
force_raster_widgets=1
ignored_applications=@Invalid()
EOF
}

# Configure Qt6CT
configure_qt6ct() {
    local mode="$1"
    local qt_style=$([ "$mode" = "dark" ] && echo "kvantum-dark" || echo "kvantum")

    cat > "$QT6CT_CONFIG" << EOF
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Adwaita
standard_dialogs=default
style=$qt_style

[Fonts]
fixed="JetBrains Mono Nerd Font,10,-1,5,50,0,0,0,0,0"
general="JetBrains Mono Nerd Font,11,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[Troubleshooting]
force_raster_widgets=1
ignored_applications=@Invalid()
EOF
}

# Configure Kvantum
configure_kvantum() {
    local mode="$1"
    local kvantum_theme=$([ "$mode" = "dark" ] && echo "KvArcDark" || echo "KvArc")

    cat > "$KVANTUM_CONFIG" << EOF
[General]
theme=$kvantum_theme

[Applications]
KvantumPreview=kvantum
EOF
}

# Apply theme function
apply_theme() {
    local mode="$1"

    echo "Applying $mode theme..."

    # Configure all theme files
    configure_qt5ct "$mode"
    configure_qt6ct "$mode"
    configure_kvantum "$mode"

    # Apply Kvantum theme for Qt apps
    local kvantum_theme=$([ "$mode" = "dark" ] && echo "KvArcDark" || echo "KvArc")
    kvantummanager --set "$kvantum_theme" 2>/dev/null || true

    # Set environment variables for current session
    export QT_QPA_PLATFORMTHEME="qt5ct"
    export QT_STYLE_OVERRIDE="kvantum"

    # Update environment for systemd user session (for new apps)
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user set-environment QT_QPA_PLATFORMTHEME="qt5ct" 2>/dev/null || true
        systemctl --user set-environment QT_STYLE_OVERRIDE="kvantum" 2>/dev/null || true
    fi
}

# Toggle between themes
toggle_theme() {
    local current_theme=$(get_current_theme)

    if [[ "$current_theme" == "dark" ]]; then
        apply_theme "light"
        set_theme_state "light"
        echo "🌞 Switched to light theme"
    else
        apply_theme "dark"
        set_theme_state "dark"
        echo "🌙 Switched to dark theme"
    fi
}


# Main function
main() {
    create_dirs

    case "${1:-toggle}" in
        "dark")
            apply_theme "dark"
            set_theme_state "dark"
            ;;
        "light")
            apply_theme "light"
            set_theme_state "light"
            ;;
        "toggle")
            toggle_theme
            ;;
        "status")
            show_status
            ;;
        "fix")
            echo "🔧 Fixing theme configuration..."
            create_dirs
            apply_theme "$(get_current_theme)"
            echo "✓ Configuration fixed"
            ;;
        *)
            echo "Usage: $0 {dark|light|toggle|status|fix}"
            echo "  dark   - Apply dark theme"
            echo "  light  - Apply light theme"
            echo "  toggle - Toggle between themes"
            echo "  status - Show current theme status"
            echo "  fix    - Fix/reset theme configuration"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
