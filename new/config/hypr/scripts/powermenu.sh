#!/bin/bash

# Варианты выбора
chosen=$(echo -e " Shutdown\n Ferdinand Reboot\n󰌾 Lock\n󰍃 Logout\n󰒲 Suspend" | rofi -dmenu -i -p "Power Menu:")

case "$chosen" in
" Shutdown") systemctl poweroff ;;
" Ferdinand Reboot") systemctl reboot ;;
"󰌾 Lock") hyprlock ;;
"󰍃 Logout") hyprctl dispatch exit ;;
"󰒲 Suspend") systemctl suspend ;;
esac
