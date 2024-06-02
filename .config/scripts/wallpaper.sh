#!/bin/bash

directory=~/.config/backgrounds
monitors=`hyprctl monitors | grep Monitor | awk '{print $2}'`

if [ -d "$directory" ]; then
    random_wal=$(ls $directory/*.{jpg,png} 2>/dev/null | shuf -n 1)
    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload $random_wal
    for monitor in ''${monitors[@]}; do
        hyprctl hyprpaper wallpaper "$monitor,$random_wal"
    done
fi