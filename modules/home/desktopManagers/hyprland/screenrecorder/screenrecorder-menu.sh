#!/usr/bin/env bash

host=$(hostname)
filename="$HOME/Videos/$(date +'screenrecord_%Y%m%d%H%M%S.mp4')"
thumbnail='/tmp/screenrec_thumbnail.png'
prompt='Screenrecord'

# Options
recorddesktop=''
recordwindow=''
recordregion=''

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "$prompt" \
		-markup-rows \
		-theme screenrecorder-menu.rasi
}

# Pass variables to rofi dmenu
show_menu() {
	echo -e "$recorddesktop\n$recordwindow\n$recordregion" | rofi_cmd
}

if screenrecorder-is-recording; then
    screenrecorder-stop
    exit 0
fi

# Actions
chosen="$(show_menu)"
case ${chosen} in
    "$recorddesktop")
		nohup "$SHELL" <<- EOF >/dev/null 2>&1 &
			wl-screenrec --filename "$filename" -g "$(slurp -o)" &&
			ffmpeg -i "$filename" -ss 00:00:00 -vframes 1 "$thumbnail" -y &&
			notify-send "Recording saved" "Saved to $filename" --icon "$thumbnail"
EOF
        ;;
    "$recordwindow")
		nohup "$SHELL" <<- EOF >/dev/null 2>&1 &
			wl-screenrec --filename "$filename" -g "$(hyprctl clients -j \
				| jq -r ".[] | select(.workspace.id \
				| IN($(hyprctl -j monitors | jq 'map(.activeWorkspace.id) | join(",")' | tr -d \")))" \
				| jq -r ".at,.size" \
				| jq -s "add" \
				| jq '_nwise(4)' \
				| jq -r '"\(.[0]),\(.[1]) \(.[2])x\(.[3])"' \
				| slurp)" && 
			ffmpeg -i "$filename" -ss 00:00:00 -vframes 1 "$thumbnail" -y &&
			notify-send "Recording saved" "Saved to $filename" --icon "$thumbnail"
EOF
        ;;
    "$recordregion")
		nohup "$SHELL" <<- EOF >/dev/null 2>&1 &
			wl-screenrec --filename "$filename" -g "$(slurp)" &&
			ffmpeg -i "$filename" -ss 00:00:00 -vframes 1 "$thumbnail" -y &&
			notify-send "Recording saved" "Saved to $filename" --icon "$thumbnail"
EOF
        ;;
esac