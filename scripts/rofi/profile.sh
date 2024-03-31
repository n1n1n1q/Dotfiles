#!/bin/bash

# Function to get the current mode
get_current_mode() {
    current_mode=$(asusctl profile -p | awk '{print $NF}')
    echo "Current mode: $current_mode"
}

# Function to change the mode
change_mode() {
    new_mode=$1
    asusctl profile -P "$new_mode"
    get_current_mode
}

# Display the current mode and get the selected mode using rofi with the custom theme
current_mode=$(get_current_mode)
selected_mode=$(echo -e "Balanced\nPerformance\nQuiet" | rofi -dmenu -p "Select a mode" -mesg "$current_mode" -location 3 -config $HOME/.config/rofi/profileSelect.rasi)

# Change the mode if a valid selection is made
case $selected_mode in
    "Balanced"|"Performance"|"Quiet")
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

