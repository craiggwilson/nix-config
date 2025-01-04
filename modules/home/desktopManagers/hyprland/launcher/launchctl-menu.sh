pkill rofi || rofi \
    -show drun \
    -theme launchctl-menu.rasi \
    -run-command 'launchctl exec {cmd}'