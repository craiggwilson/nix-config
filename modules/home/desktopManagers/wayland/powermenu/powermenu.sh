#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"
host=`hostname`

# Options
shutdown='󰐥'
reboot='󰜉'
suspend='󰒲'
lock='󰌾'
logout='󰍃'
yes=''
no='󰜺'

# Rofi CMD
rofi_cmd() {
	pkill rofi || rofi -dmenu \
		-p "$host" \
		-theme-str "textbox-prompt-colon { str: \"Uptime: $uptime\";}" \
		-theme powermenu.rasi
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 1000;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-theme-str 'message {margin: 0px;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you sure?' \
		-theme powermenu.rasi
}

# Ask for confirmation
confirm_exit() {
	echo -e "$no\n$yes" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$logout\n$suspend\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--suspend' ]]; then
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
			uwsm stop
            #loginctl terminate-session $XDG_SESSION_ID
		fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $lock)
		loginctl lock-session
        ;;
    $logout)
		run_cmd --logout
        ;;
esac