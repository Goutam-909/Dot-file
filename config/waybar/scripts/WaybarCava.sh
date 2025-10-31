#!/bin/bash

bar="▁▂▃▄▅▆▇█"
dict="s/;//g"
bar_length=${#bar}

for ((i = 0; i < bar_length; i++)); do
    dict+=";s/$i/${bar:$i:1}/g"
done

config_file="/tmp/bar_cava_config"

cat >"$config_file" <<EOF
[general]
bars = 10

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7

EOF

cava_pid=""

while true; do
    playing=$(playerctl status 2>/dev/null)
    if [[ "$playing" == "Playing" || "$playing" == "Paused" ]]; then
        if [[ -z "$cava_pid" || ! -e /proc/$cava_pid ]]; then
            cava -p "$config_file" | sed -u "$dict" | while read -r line; do
                echo "$line"
            done &
            cava_pid=$!
        fi
    else
        if [[ -n "$cava_pid" && -e /proc/$cava_pid ]]; then
            kill "$cava_pid"
            cava_pid=""
        fi
        echo ""
    fi
    sleep 1
done
