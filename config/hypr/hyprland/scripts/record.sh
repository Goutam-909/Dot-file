#!/usr/bin/env bash

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}

getaudiooutput() {
    default_sink=$(pactl info | awk -F': ' '/Default Sink/ {print $2}')
    echo "${default_sink}.monitor"
}

getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}
xdgvideo="$(xdg-user-dir VIDEOS)/Recordings"
mkdir -p "$xdgvideo"
cd "$xdgvideo" || exit

if pgrep wf-recorder > /dev/null; then
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    pkill wf-recorder &
else
    filename="./recording_$(getdate).mp4"
    if [[ "$1" == "--fullscreen-sound" ]]; then
        notify-send "Starting recording" "$filename" -a 'Recorder' & disown
        wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$filename" --audio="$(getaudiooutput)"
    elif [[ "$1" == "--fullscreen" ]]; then
        notify-send "Starting recording" "$filename" -a 'Recorder' & disown
        wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$filename"
    else
        if ! region="$(slurp 2>&1)"; then
            notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
            exit 1
        fi
        notify-send "Starting recording" "$filename" -a 'Recorder' & disown
        if [[ "$1" == "--sound" ]]; then
            wf-recorder --pixel-format yuv420p -f "$filename" --geometry "$region" --audio="$(getaudiooutput)"
        else
            wf-recorder --pixel-format yuv420p -f "$filename" --geometry "$region"
        fi
    fi
fi
