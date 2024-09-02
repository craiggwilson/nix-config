#!/usr/bin/env bash

set -e
set -u

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

# extract the keybinding from hyprland.conf
mapfile -t BINDINGS < <(grep '^bind=.*#' "$HYPR_CONF" | sed -e 's/bind=//g' -e 's/ #/,/g' -e 's/ *, /,/g')


echo -e "\0no-custom\x1ftrue"
echo -e "\0markup-rows\x1ftrue"

if [ $# -gt 0 ]
then
    # If arguments given, use those as the selection
    selection="${@}"
    if [[ "$selection" == exec,* ]]
    then
        coproc ("${selection#exec,}")
    else
        coproc ("hyprctl dispatch ${selection%,}")
    fi
else
    for line in "${BINDINGS[@]}"; do
        IFS=,; read -ra fields <<<"$line"
        echo -e "${fields[2]},${fields[3]}\0display\x1f<b>${fields[0]} + ${fields[1]}</b>  <i><span color='gray'>${fields[4]}</span></i>"
    done
fi

