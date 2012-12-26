file mkdir data

#-------------------------------------------------------------------------------
proc wget {url {encoding {utf-8}}} {
    set data ""
    catch {
        set fd [open "|wget -q -O - $url 2> /dev/null"]
        fconfigure $fd -encoding $encoding
        set data [read $fd]
    }
    catch {
        close $fd
    }
    return $data
}
proc now {} {
    return [clock seconds]
}
#-------------------------------------------------------------------------------

#http://92flv.com/?url=http%3A%2F%2Fwww.tudou.com%2Flistplay%2FyZbsvUhF6ew%2FIFmZsdGDmSM.html
#http://92flv.com/?url=http%3A%2F%2Fwww.tudou.com%2Flistplay%2FP5DoRCB9sPw%2FAVuZWD-lViY.html

proc update_vid_url {url} {
    global v_files v_order

    set param $url
    regsub -all ":" $param %3A param
    regsub -all "/" $param %2F param

    set url92 http://92flv.com/?url=$param
    puts $url92

    set vidurl ""
    for {set i 0} {$i < 3} {incr i} {
        if {$i > 0} {
            set try " -- try # [expr $i + 1]"
        } else {
            set try ""
        }
        set started [now]
        puts -nonewline "... getting video URL for $v_files($url)$try"
        flush stdout
        set data [wget $url92]
        #set data [exec cat /tmp/foo.txt]
        puts " [expr [now] - $started] secs"

        foreach res {480 360} {
            set d $data
            regsub ".*>P${res}</a>" $d "" d
            regsub "</div>.*" $d "" d
            if {[regexp {javascript:getFile.'([^']+)} $d dummy vidurl]} {
                regsub -all {&amp;} $vidurl "\\&" vidurl
                puts "--P$res"
                puts $vidurl
                break
            }
        }

        if {"$vidurl" != ""} {
            break
        }
    }

    if {"$vidurl" != ""} {
        set v_files($url,vid) $vidurl
        return 1
    } else {
        return 0
    }
}


proc download {url} {
    global v_files v_order

    set name $v_files($url)
    if {[file ext $name] == ""} {
        set name $name.f4v
    }
    set vidfile data/$name
    if {[file exists $vidfile]} {
        puts "$name: already exists $vidfile"
        return 1
    }

    puts "\n--------------------------------------------------$name - starting"
    if {![info exists v_files($url,vid)]} {
        if {![update_vid_url $url]} {
            return 0
        }
    }

    set started [now]
    set vidurl $v_files($url,vid)
    if {[catch {
        file delete $vidfile.part
        exec wget --tries=1 --read-timeout=60 -O $vidfile.part $vidurl >@ stdout 2>@ stdout
        file rename $vidfile.part $vidfile
    } err]} {
        puts -nonewline "$name FAILED ($err)"
    } else {
        puts -nonewline "$name SUCCEEED"
    }

    set size 0
    if {[file exists $vidfile.part]} {
        set size [file size $vidfile.part]
    } elseif {[file exists $vidfile]} {
        set size [file size $vidfile]
    } 

    set elapsed [expr [now] - $started]
    set speed [format %.1f [expr $size / (1024.0 * $elapsed+0.01)]]
    puts " $size bytes / $elapsed secs = $speed KB/sec"

    return 0
}

proc download_in_order {} {
    global v_files v_order

    while 1 {
        set ok 1
        foreach url $v_order {
            if {![download $url]} {
                set ok 0
            }
        }

        if {$ok} {
            break
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
            if {[regexp {^([^ ]+) (.+)} $line dummy url name]} {
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

parray v_files

