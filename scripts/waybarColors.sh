#!/bin/bash
wal_cache_file="$HOME/.cache/wal/colors-waybar.css"
waybar_config_dir="$HOME/.config/waybar"
if [ -e "$wal_cache_file" ]; then
	mkdir -p "$waybar_config_dir"
	cp "$wal_cache_file" "$waybar_config_dir"
	echo "executed"
else
	echo "lol"
fi
exit
