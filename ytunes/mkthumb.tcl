# create thumbnail images next to the original video file

# Returns {duration bitrate}
proc video_info {file} {
    set secs 0
    set bitrate 1000000

    set out ""
    set err ""
    catch {
        set out [exec ffmpeg -i $file]
    } err
    append out $err

    if {[regexp {Duration: (..:..:..)} $out dummy duration]} {
        regsub -all " " $duration 0 duration
        regexp {(..):(..):(..)} $duration dummy h m s
        regsub ^0 $h "" h
        regsub ^0 $m "" m
        regsub ^0 $s "" s
        set secs [expr $h * 3600 + $m * 60 + $s]
    }

    regexp {bitrate: ([0-9]+) kb/s} $out dummy bitrate

    return [list $secs $bitrate]
}

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
        set list [video_info $file]
        set secs [lindex $list 0]
        set bitrate  [lindex $list 1]

        puts $secs--$bitrate
        if {$bitrate > 3000} {
            # dont create (may be too long)
            # cannot be played over network (by ipad, etc??) anyway
            continue
        }

        if {$secs < 100} {
            set secs [expr int($secs / (24.0 + rand()))]
        } else {
            set secs [expr int(7 + rand() * 12)]
        }
        set secs [format %02d:%02d:%02d \
                      [expr ($secs / 3600)] \
                      [expr ($secs % 3600) / 60]  \
                      [expr ($secs % 60)]]
        puts stderr "\n\nSECS=$secs\n"
	set tmpfile /tmp/mkthumb-pid.jpg
        if {[catch {
            exec ffmpeg -i $file -ss $secs -f image2 -vframes 1 -vf scale=256:-1 $tmpfile \
                >@ stdout 2>@ stdout
        }]} {
            puts stderr "FAILED THUMB: $file"
        } else {
            puts stderr "DONE   THUMB: $file"
	    file delete -force $thumb
            file copy -force $tmpfile $thumb
        }
	file delete -force $tmpfile
        #puts "start \"$thumb\""
        #exit
    }
}

