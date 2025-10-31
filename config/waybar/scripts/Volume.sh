#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for volume controls for audio and mic 

iDIR="$HOME/.config/waybar/volume-icons"

# Get Volume
get_volume() {
    volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2*100"%"}')
    if [[ "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -i muted)" != "" ]]; then
        echo "Muted"
    else
        echo "$volume"
    fi
}

# Get icons
get_icon() {
    current=$(get_volume)
    if [[ "$current" == "Muted" ]]; then
        echo "$iDIR/muted-speaker.svg"
    else
        # Extract volume percentage, removing the % symbol
        vol_num=${current%\%}
        
        # Round down to nearest 5
        vol_rounded=$(( (vol_num / 5) * 5 ))
        
        # Limit to 100 if it somehow goes higher
        if [[ $vol_rounded -gt 100 ]]; then
            vol_rounded=100
        fi
        
        echo "$iDIR/vol-$vol_rounded.svg"
    fi
}

# Notify
notify_user() {
    if [[ "$(get_volume)" == "Muted" ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" " Volume:" " Muted"
    else
        notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" " Volume Level:" " $(get_volume)"
    fi
}

# Increase Volume
inc_volume() {
    if [[ "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -i muted)" != "" ]]; then
        toggle_mute
    else
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.5 && notify_user
    fi
}

# Decrease Volume
dec_volume() {
    if [[ "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -i muted)" != "" ]]; then
        toggle_mute
    else
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify_user
    fi
}

# Toggle Mute
toggle_mute() {
    if [[ "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -i muted)" == "" ]]; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify-send -e -u low -i "$iDIR/muted-speaker.svg" " Mute"
    else
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify-send -e -u low -i "$iDIR/unmuted-speaker.svg" " Volume:" " Switched ON"
    fi
}

# Toggle Mic
toggle_mic() {
    if [[ "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -i muted)" == "" ]]; then
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && notify-send -e -u low -i "$iDIR/muted-mic.svg" " Microphone:" " Switched OFF"
    else
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && notify-send -e -u low -i "$iDIR/unmuted-mic.svg" " Microphone:" " Switched ON"
    fi
}

# Get Mic Icon
get_mic_icon() {
    if [[ "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -i muted)" != "" ]]; then
        echo "$iDIR/muted-mic.svg"
    else
        echo "$iDIR/unmuted-mic.svg"
    fi
}

# Get Microphone Volume
get_mic_volume() {
    volume=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print $2*100"%"}')
    if [[ "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -i muted)" != "" ]]; then
        echo "Muted"
    else
        echo "$volume"
    fi
}

# Notify for Microphone
notify_mic_user() {
    volume=$(get_mic_volume)
    icon=$(get_mic_icon)
    notify-send -e -h int:value:"${volume%\%}" -h "string:x-canonical-private-synchronous:volume_notif" -u low -i "$icon"  " Mic Level:" " $volume"
}

# Increase MIC Volume
inc_mic_volume() {
    if [[ "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -i muted)" != "" ]]; then
        toggle_mic
    else
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+ && notify_mic_user
    fi
}

# Decrease MIC Volume
dec_mic_volume() {
    if [[ "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -i muted)" != "" ]]; then
        toggle_mic
    else
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%- && notify_mic_user
    fi
}

# Execute accordingly
if [[ "$1" == "--get" ]]; then
	get_volume
elif [[ "$1" == "--inc" ]]; then
	inc_volume
elif [[ "$1" == "--dec" ]]; then
	dec_volume
elif [[ "$1" == "--toggle" ]]; then
	toggle_mute
elif [[ "$1" == "--toggle-mic" ]]; then
	toggle_mic
elif [[ "$1" == "--get-icon" ]]; then
	get_icon
elif [[ "$1" == "--get-mic-icon" ]]; then
	get_mic_icon
elif [[ "$1" == "--mic-inc" ]]; then
	inc_mic_volume
elif [[ "$1" == "--mic-dec" ]]; then
	dec_mic_volume
else
	get_volume
fi
