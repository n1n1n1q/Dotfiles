#!/bin/bash

output=$(killall hypridle 2>&1)

if [[ $output == *"hypridle: no process found"* ]]; then
	notify-send "Starting hypridle" "Hypridle is not running. Starting it."
	exec hypridle
else
	notify-send "Killing hypridle" "hypridle was running. Killed all instances."
fi
