shotdesktop=''
shotwindow=''
shotregion=''

show_capture_menu() {
	echo -e "$shotdesktop\n$shotwindow\n$shotregion" | vicinae dmenu -p "Screenshot"
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
