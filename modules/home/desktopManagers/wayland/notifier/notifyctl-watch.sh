while sleep 2; do 
    DND=$(makoctl mode | rg 'do-not-disturb' || true)
    HAS_ITEMS=$(makoctl list)

    if [[ "$DND" == 'do-not-disturb' ]]; then
        if [[ "${HAS_ITEMS:-0}" == "0" ]]; then
            echo '{"text": "󰂛", "tooltip": "disabled", "class": "disabled"}'
        else
            echo '{"text": "󰂛", "tooltip": "disabled", "class": ["disabled", "some"]}'
        fi
    else 
        if [[ "${HAS_ITEMS:-0}" == "0" ]]; then
            echo '{"text": "󰂚", "tooltip": "enabled", "class": "enabled"}'
        else
            echo '{"text": "󱅫", "tooltip": "enabled", "class": ["enabled", "some"]}'
        fi
    fi
done
