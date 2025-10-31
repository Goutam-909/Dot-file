#!/bin/bash

# Rofi web search with logo selection

LOGO_DIR="$HOME/.config/rofi/search-logos"
CACHE_FILE="/tmp/rofi-search-engine"
QUERY_FILE="/tmp/rofi-search-query"
#BROWSER="flatpak run org.mozilla.firefox" #--new-window"
BROWSER="chromium-browser"

# Get current engine
get_engine() {
    if [ -f "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    else
        echo "google"
    fi
}

# Set engine
set_engine() {
    echo "$1" > "$CACHE_FILE"
}

# Get query from temp file
get_query() {
    if [ -f "$QUERY_FILE" ]; then
        cat "$QUERY_FILE"
    fi
}

# Save query to temp file
save_query() {
    echo "$1" > "$QUERY_FILE"
}

# Get engine display name
get_engine_name() {
    local engine=$(get_engine)
    case "$engine" in
        "youtube") echo "YouTube Search" ;;
        "ytm") echo "YouTube Music Search" ;;
        "chatgpt") echo "ChatGPT Search" ;;
        "duckduckgo") echo "DuckDuckGo Search" ;;
        "flathub") echo "Flathub Search" ;;
        *) echo "Google Search" ;;
    esac
}

# Show search interface
show_interface() {
    local engine=$(get_engine)
    local engine_name=$(get_engine_name)
    local query=$(get_query)

    # Create list with logos only - 4 columns x 2 rows = 8 boxes
    # Use zero-width space as text to hide labels
    {
        echo -en "​\0icon\x1f${LOGO_DIR}/google.png\x1fmeta\x1fGoogle\n"
        echo -en "​\0icon\x1f${LOGO_DIR}/youtube.png\x1fmeta\x1fYouTube\n"
        echo -en "​\0icon\x1f${LOGO_DIR}/play.png\x1fmeta\x1fYouTube Music\n"
        echo -en "​\0icon\x1f${LOGO_DIR}/chatgpt.png\x1fmeta\x1fChatGPT\n"
        echo -en "​\0icon\x1f${LOGO_DIR}/duckduck.png\x1fmeta\x1fDuckDuckGo\n"
        echo -en "​\0icon\x1f${LOGO_DIR}/flathub.png\x1fmeta\x1fFlathub\n"
        echo -en "​\0icon\x1f${LOGO_DIR}/empty.png\x1fmeta\x1fEmpty1\n"
        echo -en "​\0icon\x1f${LOGO_DIR}/empty.png\x1fmeta\x1fEmpty2\n"
    } | rofi -dmenu -i -p "Search" \
        -theme ~/.config/rofi/web-search.rasi \
        -mesg "Current: $engine_name" \
        -filter "$query" \
        -format "i:s:f" \
        -selected-row $(get_selected_row)
}

# Get selected row based on current engine
get_selected_row() {
    local engine=$(get_engine)
    case "$engine" in
        "google") echo "0" ;;
        "youtube") echo "1" ;;
        "ytm") echo "2" ;;
        "chatgpt") echo "3" ;;
        "duckduckgo") echo "4" ;;
        "flathub") echo "5" ;;
        *) echo "0" ;;
    esac
}

# Map row number to engine
get_engine_from_row() {
    case "$1" in
        "0") echo "Google" ;;
        "1") echo "YouTube" ;;
        "2") echo "YouTube Music" ;;
        "3") echo "ChatGPT" ;;
        "4") echo "DuckDuckGo" ;;
        "5") echo "Flathub" ;;
        "6") echo "Empty1" ;;
        "7") echo "Empty2" ;;
        *) echo "" ;;
    esac
}

# Parse input for engine prefix
parse_input() {
    local input="$1"

    # Check for yt prefix
    if [[ "$input" =~ ^yt[[:space:]](.*)$ ]]; then
        set_engine "youtube"
        echo "${BASH_REMATCH[1]}"
        return 0
    elif [ "$input" = "yt" ]; then
        set_engine "youtube"
        echo ""
        return 1
    fi

    # Check for ytm prefix
    if [[ "$input" =~ ^ytm[[:space:]](.*)$ ]]; then
        set_engine "ytm"
        echo "${BASH_REMATCH[1]}"
        return 0
    elif [ "$input" = "ytm" ]; then
        set_engine "ytm"
        echo ""
        return 1
    fi

    # Check for chatgpt prefix
    if [[ "$input" =~ ^(chatgpt|gpt)[[:space:]](.*)$ ]]; then
        set_engine "chatgpt"
        echo "${BASH_REMATCH[2]}"
        return 0
    elif [ "$input" = "chatgpt" ] || [ "$input" = "gpt" ]; then
        set_engine "chatgpt"
        echo ""
        return 1
    fi

    echo "$input"
    return 0
}

# Perform search
do_search() {
    local query="$1"
    local engine=$(get_engine)

    if [ -z "$query" ]; then
        return
    fi

    encoded=$(echo "$query" | sed 's/ /+/g')

    case "$engine" in
        "youtube")
            $BROWSER "https://www.youtube.com/results?search_query=$encoded" >/dev/null 2>&1 &
            ;;
        "ytm")
            $BROWSER "https://music.youtube.com/search?q=$encoded" >/dev/null 2>&1 &
            ;;
        "chatgpt")
            $BROWSER "https://chatgpt.com/?q=$encoded" >/dev/null 2>&1 &
            ;;
        "duckduckgo")
            $BROWSER "https://duckduckgo.com/?q=$encoded" >/dev/null 2>&1 &
            ;;
        "flathub")
            $BROWSER "https://flathub.org/apps/search?q=$encoded" >/dev/null 2>&1 &
            ;;
        *)
            $BROWSER "https://www.google.com/search?q=$encoded" >/dev/null 2>&1 &
            ;;
    esac
}

# Main loop
main() {
    # Clear query file on start
    rm -f "$QUERY_FILE"

    while true; do
        result=$(show_interface)

        # Exit if cancelled
        if [ $? -ne 0 ]; then
            rm -f "$QUERY_FILE" "$CACHE_FILE"
            exit 0
        fi

        # Parse the result format "index:selected_text:filter_text"
        index=$(echo "$result" | cut -d: -f1)
        selected_text=$(echo "$result" | cut -d: -f2)
        filter_text=$(echo "$result" | cut -d: -f3-)

        # If user clicked a logo (selected text is zero-width space or empty)
        if [ "$selected_text" = "​" ] || [ -z "$selected_text" ]; then
            engine_name=$(get_engine_from_row "$index")

            case "$engine_name" in
                "Google")
                    set_engine "google"
                    continue
                    ;;
                "YouTube")
                    set_engine "youtube"
                    continue
                    ;;
                "YouTube Music")
                    set_engine "ytm"
                    continue
                    ;;
                "ChatGPT")
                    set_engine "chatgpt"
                    continue
                    ;;
                "DuckDuckGo")
                    set_engine "duckduckgo"
                    continue
                    ;;
                "Flathub")
                    set_engine "flathub"
                    continue
                    ;;
                "Empty1"|"Empty2")
                    # Ignore empty boxes
                    continue
                    ;;
            esac
        fi

        # User typed something and pressed Enter
        # Save current query
        save_query "$filter_text"

        # Parse input for prefix commands
        if [ -n "$filter_text" ]; then
            parsed=$(parse_input "$filter_text")
            parse_result=$?

            if [ $parse_result -eq 1 ]; then
                # Prefix detected but no query yet, continue
                continue
            fi

            # Perform search and exit
            if [ -n "$parsed" ]; then
                do_search "$parsed"
                rm -f "$QUERY_FILE" "$CACHE_FILE"
                exit 0
            fi
        fi
    done
}

main
