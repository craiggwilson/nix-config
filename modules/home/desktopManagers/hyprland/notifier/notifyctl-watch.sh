while true; do 
    DND=$(makoctl mode | rg 'do-not-disturb' || true)
    COUNT=$(makoctl list | jq -e '.data[] | length')

    if [[ "$DND" == 'do-not-disturb' ]]; then
        if [[ "$COUNT" == "0" ]]; then
            echo '{"text": "󰂛", "tooltip": "disabled", "class": "disabled"}'
        else
            echo '{"text": "󰂛", "tooltip": "disabled", "class": ["disabled", "some"]}'
        fi
    else 
        if [[ "$COUNT" == "0" ]]; then
            echo '{"text": "󰂚", "tooltip": "enabled", "class": "enabled"}'
        else
            echo '{"text": "󱅫", "tooltip": "enabled", "class": ["enabled", "some"]}'
        fi
    fi
    sleep 1; 
done
