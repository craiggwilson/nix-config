#!/usr/bin/env bash

host=`hostname`
filename="$XDG_VIDEOS_DIR/$(date +'screenrecord_%Y%m%d%H%M%S.mp4')"
thumbnail="/tmp/screenrec_thumbnail.png"
prompt='Screenrecord'
list_col='1'
list_row='3'
win_width='400px'

# Options
recorddesktop=""
recordwindow=""
recordregion=""

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p $host \
		-mesg "$prompt" \
		-markup-rows \
		-theme screenrecordmenu.rasi
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$recorddesktop\n$recordwindow\n$recordregion" | rofi_cmd
}

# If wl-screenrec is already running, stop recording.
if pgrep -x "wl-screenrec" > /dev/null; then
    pkill wl-screenrec
    exit 0
fi

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $recorddesktop)
		wl-screenrec --filename $filename -g "$(slurp -o)" &&
		ffmpeg -i "$filename" -ss 00:00:00 -vframes 1 "$thumbnail" -y &&
		notify-send "Recording saved" "Saved to $filename" --icon "$thumbnail" &
        ;;
    $recordwindow)
		wl-screenrec --filename $filename -g "$(hyprctl clients -j \
			| jq -r ".[] | select(.workspace.id \
			| IN($(hyprctl -j monitors | jq 'map(.activeWorkspace.id) | join(",")' | tr -d \")))" \
			| jq -r ".at,.size" \
			| jq -s "add" \
			| jq '_nwise(4)' \
			| jq -r '"\(.[0]),\(.[1]) \(.[2])x\(.[3])"' \
			| slurp)" && 
		ffmpeg -i "$filename" -ss 00:00:00 -vframes 1 "$thumbnail" -y &&
		notify-send "Recording saved" "Saved to $filename" --icon "$thumbnail" &
        ;;
    $recordregion)
		wl-screenrec --filename $filename -g "$(slurp)" &&
		ffmpeg -i "$filename" -ss 00:00:00 -vframes 1 "$thumbnail" -y &&
		notify-send "Recording saved" "Saved to $filename" --icon "$thumbnail" &
        ;;
esac