# create thumbnail images next to the original video file
set files {}

catch {
    set fd [open "|find . -name \*.mp4 -print -o -name \*.m4v -print" r]
    while {![eof $fd]} {
        set file [gets $fd]
        if {"$file" == ""} {
            continue
        }
        lappend files $file
    }
    close $fd
}

foreach file $files {
    set thumb [file dirname $file]/.[file tail $file].jpg
    if {![file exists $thumb] || [info exists env(FORCE)]} {
        set secs 0
        catch {
            set duration [string trim [exec exiftool $file | grep {^Duration}]]
            if {[regexp {(..:..:..)$} $duration dummy duration]} {
                regsub -all " " $duration 0 duration
                regexp {(..):(..):(..)} $duration dummy h m s
                regsub ^0 $h "" h
                regsub ^0 $m "" m
                regsub ^0 $s "" s
                set secs [expr $h * 3600 + $m * 60 + $s]
            }
        }
        if {$secs < 100} {
            set secs [expr int($secs / (24.0 + rand()))]
        } else {
            set secs [expr int(10 + rand() * 10)]
        }
        set secs [format %02d:%02d:%02d \
                      [expr ($secs / 3600)] \
                      [expr ($secs % 3600) / 60]  \
                      [expr ($secs % 60)]]
        puts stderr "\n\nSECS=$secs\n"
        if {[catch {
            exec ffmpeg -i $file -ss $secs -f image2 -vframes 1 -vf scale=256:-1 $thumb.tmp \
                >@ stdout 2>@ stdout
        }]} {
            puts stderr "FAILED THUMB: $file"
            file delete -force $thumb.tmp
        } else {
            puts stderr "DONE   THUMB: $file"
            file rename -force $thumb.tmp $thumb
        }
        #puts "start \"$thumb\""
        #exit
    }
}

