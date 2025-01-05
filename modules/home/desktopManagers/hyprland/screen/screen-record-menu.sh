recorddesktop=''
recordwindow=''
recordregion=''

if screenctl record is-recording; then
    screenctl record stop
    exit 0
fi

# Pass variables to rofi dmenu
show_record_menu() {
	echo -e "$recorddesktop\n$recordwindow\n$recordregion" | rofi -dmenu \
		-p "$(hostname)" \
		-markup-rows \
		-theme screen-record-menu.rasi
}

# Actions
chosen="$(show_record_menu)"
case ${chosen} in
    "$recorddesktop")
		screenctl record desktop
        ;;
    "$recordwindow")
		screenctl record window
        ;;
    "$recordregion")
		screenctl record region
        ;;
esac
