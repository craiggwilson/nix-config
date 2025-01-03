while true; do 
    if screenrecorder-is-running; then
        echo '󰑊'
    else 
        echo ''
    fi
    sleep 1; 
done
