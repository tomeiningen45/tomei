while true; do
    echo ======================================================================$(date)
    tclsh yt.tcl
    ./youtube-dl -U
    sleep 600
done
