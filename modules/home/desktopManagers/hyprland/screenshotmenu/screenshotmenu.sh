#!/usr/bin/env bash

host=`hostname`
prompt='Screenshot'
list_col='1'
list_row='3'
win_width='400px'

# Options
shotdesktop=""
shotwindow=""
shotregion=""

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p $host \
		-mesg "$prompt" \
		-markup-rows \
		-theme screenshotmenu.rasi
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$shotdesktop\n$shotwindow\n$shotregion" | rofi_cmd
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shotdesktop)
		hyprshot -m output --clipboard-only
        ;;
    $shotwindow)
		hyprshot -m window --clipboard-only 
        ;;
    $shotregion)
		hyprshot -m region --clipboard-only
        ;;
esac