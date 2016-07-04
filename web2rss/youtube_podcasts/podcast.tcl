
foreach i $FILES {
    set file $i
    regsub {.*=} $file "" file

    set file ./$file
    if {[file exists $file.mp3]} {
        continue
    }
    if {![file exists $file.mp4]} {
        exec ~/youtube/youtube-dl -o $file.mp4 $i >@ stdout 2>@ stderr
    }
    if {![file exists $file.html]} {
        exec wget -O $file.html $i  >@ stdout 2>@ stderr
    }

    set fd [open $file.html]
    fconfigure $fd -encoding utf-8
    set data [read $fd]
    close $fd

    set title ""
    set comments ""

    regexp {<title>([^<]+)</title>} $data dummy title
    regsub { - YouTube$} $title "" title
    regexp {name="description" content="([^<]+)">} $data dummy comments

    set out $file.mp3

    exec /Applications/VLC.app/Contents/MacOS/VLC -I dummy $file.mp4 "--sout=#transcode{acodec=mp3,vcodec=dummy}:standard{access=file,mux=raw,dst=$file.mp3}" vlc://quit \
        >@ stdout 2>@ stderr

    exec eyed3 -2 -A $album -a $artist -c $comments -G Podcast -t $title $file.mp3 >@ stdout 2>@ stderr
}
