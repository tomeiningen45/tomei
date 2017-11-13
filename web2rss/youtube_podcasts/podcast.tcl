
foreach i $FILES {
    set file $i
    regsub {.*=} $file "" file

    set file ./$file
    if {[file exists $file.mp3]} {
        continue
    } else {
        exec ~/youtube/youtube-dl -x --audio-format wav -o $file.wav $i >@ stdout 2>@ stderr
        exec ffmpeg -i $file.wav -codec:a libmp3lame -qscale:a 2 $file.mp3 >@ stdout 2>@ stderr
        file delete -force $file.wav
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

    exec eyed3 -2 -A $album -a $artist -c $comments -G Podcast -t $title $file.mp3 >@ stdout 2>@ stderr
}
