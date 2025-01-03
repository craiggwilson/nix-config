while true; do 
    if screenrecorder-is-recording; then
        echo '󰑊'
    else 
        echo ''
    fi
    sleep 1; 
done
