set instdir [file dirname [info script]]
source $instdir/lib.tcl

file mkdir data

proc code {a b} {
    if {$a == $b} {
        return 0
    } elseif {$a > $b} {
        return 1
    } else {
        return -1
    }
}

proc compare {a b} {
    # Fixme - make these configurable
    set max 480
    set min 360
    # 

    set prefer(webm) 0
    set prefer(flv)  1
    set prefer(mp4)  2

    set typea [lindex $a 1]
    set typeb [lindex $b 1]
    set resa [lindex $a 2]
    set resb [lindex $b 2]

    if {$resa == $resb} {
        return [code $prefer($typea) $prefer($typeb)]
    }

    if {$resa > $max && $resb > $max} {
        return [code $resb $resa]
    }

    if {$resa < $min && $resb < $min} {
        return [code $resa $resb]
    }

    if {$resa > $max && $resb < $min} {
        return 1
    }

    if {$resb > $max && $resa < $min} {
        return -1
    }

    if {$resa > $max} {
        return -1
    }
    if {$resb > $max} {
        return 1
    }

    if {$resa < $min} {
        return -1
    }
    if {$resb < $min} {
        return 1
    }

    return [code $resa $resb]
}

proc download {url} {
    global v_files v_order instdir

    set name $v_files($url)
    set vidfile data/$name

    foreach f [glob -nocomplain $vidfile*] {
        if {![regexp {[.]part$} $f]} {
            puts "$name: already exists $f"
            return 1
        }
    }

    puts "\n--------------------------------------------------$name - starting"
    set started [now]
    puts -nonewline "Get available formats "
    flush stdout
    if {[catch {
        set formats [exec $instdir/youtube-dl -F $url]
    }]} {
        puts "Cannot get available formats $url"
        return 0
    }

    foreach line [split $formats \n] {
        if {[regexp {([0-9]+).:.([a-z0-9]+)..([0-9]+)} $line dummy format type res]} {
            lappend list [list $format $type $res]
        }
    }

    set list [lsort -command compare $list]
    set format [lindex $list end]
    #set format [lindex $list 0]

    puts "<$format> $list [expr [now] - $started] secs"

    set vidfile $vidfile.[lindex $format 1]
    set fmtcode [lindex $format 0]
    set started [now]
    if {[catch {
        exec $instdir/youtube-dl -f $fmtcode -o $vidfile --no-continue --no-mtime $url >@ stdout 2>@ stdout
    } err]} {
        puts -nonewline "$name FAILED ($err)"
    } else {
        puts -nonewline "$name SUCCEEED"
    }

    set size 0
    if {[file exists $vidfile]} {
        set size [file size $vidfile]
    } 

    set elapsed [expr [now] - $started]
    set speed [format %.1f [expr $size / (1024.0 * $elapsed+0.01)]]
    puts " $size bytes / $elapsed secs = $speed KB/sec"

    return 0
}

proc download_in_order {} {
    global v_files v_order

    for {set i 0} {$i < 10} {incr i} {
        set ok 1
        set failed {}
        foreach url $v_order {
            if {![download $url]} {
                set ok 0
                lappend failed $url
            }
        }

        if {$ok} {
            break
        }
    }

    if {!$ok} {
        puts "Some files are still not downloaded"
        foreach url $failed {
            puts "  $v_files($url)"
        }
    }
}

proc read_index {files} {
    global v_files v_order

    foreach file $files {
        set fd [open $file]
        fconfigure $fd -encoding utf-8
        while {![eof $fd]} {
            set line [gets $fd]
            if {[regexp {^ *([0-9]+) (http[^ ]+) (.+)} $line dummy dummy url name]} {
                if {![info exists v_files($url)]} {
                    set v_files($url) $name
                    lappend v_order $url
                }
            }
        }
    }             
}

read_index $argv
download_in_order

puts "All done!"

