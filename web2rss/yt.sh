while true; do
    echo ======================================================================$(date)
    tclsh yt.tcl
    ./youtube-dl -U

    if test "x$OS" = "xWindows_NT"; then
	./yt-dlp_x86.exe -U
    else
	./yt-dlp -U
    fi
    sleep 600
done
