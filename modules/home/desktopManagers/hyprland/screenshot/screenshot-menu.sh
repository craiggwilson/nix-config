#!/usr/bin/env bash

host=$(hostname)
prompt='Screenshot'

# Options
shotdesktop=''
shotwindow=''
shotregion=''

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "$prompt" \
		-markup-rows \
		-theme screenshot-menu.rasi
}

# Pass variables to rofi dmenu
show_menu() {
	echo -e "$shotdesktop\n$shotwindow\n$shotregion" | rofi_cmd
}

# Actions
chosen="$(show_menu)"
case ${chosen} in
    "$shotdesktop")
		hyprshot -m output --clipboard-only
        ;;
    "$shotwindow")
		hyprshot -m window --clipboard-only 
        ;;
    "$shotregion")
		hyprshot -m region --clipboard-only
        ;;
esac