#!/bin/bash

output=$(killall swayidle 2>&1)

if [[ $output == *"swayidle: no process found"* ]]; then
    notify-send "Starting swayidle" "Swayidle is not running. Starting it."
    scripts/autosuspend
else
    notify-send "Killing swayidle" "Swayidle was running. Killed all instances."
fi
