#!/bin/bash

get_current_mode() {
    current_mode=$(asusctl profile -p | awk '{print $NF}')
    echo "Current mode: $current_mode"
}

change_mode() {
    new_mode=$1
    asusctl profile -P "$new_mode"
    get_current_mode
}

current_mode=$(get_current_mode)
selected_mode=$(echo -e "Balanced\nPerformance\nQuiet" | wofi --dmenu --height 200 --width 300 --y 0 --x 1620 --prompt "Select a mode" --initial-input "$current_mode")

case $selected_mode in
    "Balanced" | "Performance" | "Quiet")
        change_mode "$selected_mode"
        ;;
    "")
        echo "No selection made. Exiting script."
        exit 1
        ;;
    *)
        echo "Invalid selection. Exiting script."
        exit 1
        ;;
esac
