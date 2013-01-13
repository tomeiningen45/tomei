echo "starting side loop (wait 100 second for very first time)"
sleep 100
while true; do
    cp side_sync.sh run_sidesync.sh
    sh run_sidesync.sh
    sleep 300
done
