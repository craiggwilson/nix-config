recorddesktop=''
recordwindow=''
recordregion=''

if screenctl record is-recording; then
    screenctl record stop
    exit 0
fi

# Pass variables to vicinae dmenu
show_record_menu() {
	echo -e "$recorddesktop\n$recordwindow\n$recordregion" | vicinae dmenu -p "Record"
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
