shotdesktop=''
shotwindow=''
shotregion=''

show_capture_menu() {
	echo -e "$shotdesktop\n$shotwindow\n$shotregion" | rofi -dmenu \
		-p "$(hostname)" \
		-markup-rows \
		-theme screen-capture-menu.rasi
}

# Actions
chosen="$(show_capture_menu)"
case ${chosen} in
    "$shotdesktop")
		screenctl capture desktop
        ;;
    "$shotwindow")
		screenctl capture window
        ;;
    "$shotregion")
		screenctl capture region
        ;;
esac
