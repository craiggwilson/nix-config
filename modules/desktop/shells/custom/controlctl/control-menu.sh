volume='󰕾  Volume'
brightness='󰃠  Brightness'
power='󰐥  Power menu'
lock='󰌾  Lock'
settings='󰒓  Settings'

choice="$({
    printf '%s\n' "$volume"
    printf '%s\n' "$brightness"
    printf '%s\n' "$power"
    printf '%s\n' "$lock"
    printf '%s\n' "$settings"
  } | vicinae dmenu -p 'Control center')"

case "$choice" in
  "$volume")
    audioctl output show-menu
    ;;
  "$brightness")
    screenctl backlight get
    ;;
  "$power")
    vicinae 'vicinae://launch/power?toggle=true'
    ;;
  "$lock")
    hyprlock
    ;;
  "$settings")
    vicinae 'vicinae://settings/open'
    ;;
esac
