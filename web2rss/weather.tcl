source [file dirname [info script]]/rss-lib.tcl

proc should_update {} {
    # Update the images every 3am
    set ref_hr 3

    set cur_hr [clock format [clock seconds] -format %H]
    regsub ^0+ $cur_hr "" cur_hr

    if {$cur_hr < $ref_hr} {
        return false
    } else {
        return true
    }
}

proc set_update_timestamp {image_root} {
    set ts 0
    catch {
        set ts [file mtime $image_root/timestamp.js]
    }

    set now [clock seconds]
    set tsdate [string trim [clock format $ts -format %e]]
    set today [string trim [clock format $now -format %e]]

    if {$tsdate != $today} {
        puts "Updating timestamp.js"
        set fd [open $image_root/timestamp.js w+]
        puts $fd "day = new Array(7);"
        for {set i 0} {$i < 7} {incr i} {
            set t [expr $now + $i * 86400]
            puts $fd "day\[$i\] = \"[clock format $t -format %a]\";"
        }
        close $fd
    }

    return [file mtime $image_root/timestamp.js]
}

proc all_images {} {
    set list {}
    for {set n 0} {$n <= 144} {incr n 3} {
        if {$n < 10} {
            lappend list 00$n
        } elseif {$n < 100} {
            lappend list 0$n
        } else {
            lappend list $n
        }
    }

    return $list
}

proc fetch_if_needed {image_root ts level num} {
    set imgfile $image_root/${level}_${num}.jpg
    set tmpfile $image_root/${level}_${num}_tmp.jpg
    set smlfile $image_root/${level}_${num}_tmp_small.jpg

    if {[file exists $imgfile] && [file mtime $imgfile] >= $ts} {
        return true;
    }
    if {[file exists $tmpfile] && [file mtime $tmpfile] >= $ts} {
        return true;
    }

    set url https://polar.ncep.noaa.gov/nwps/images/rtimages/mtr/nwps/CG${level}/swan_sigwaveheight_hr${num}.png
    if {[catch {
        puts "Getting $url"
        set tmp $tmpfile.png
        exec wget -q -O $tmp $url

        exec ffmpeg -hide_banner -loglevel error -i $tmp -vf "crop=590:550:195:75,scale=100:100" $smlfile
        exec ffmpeg -hide_banner -loglevel error -i $tmp -q:v 10 $tmpfile
        file delete -force $tmp
    } err]} {
        puts $err
        return false
    }

    return true
}

proc rename_if_needed {image_root ts level num} {
    set imgfile $image_root/${level}_${num}.jpg
    set tmpfile $image_root/${level}_${num}_tmp.jpg

    set imgfile_small $image_root/${level}_${num}_small.jpg
    set tmpfile_small $image_root/${level}_${num}_tmp_small.jpg

    if {[file exists $tmpfile]} {
        file rename -force $tmpfile $imgfile
    }

    if {[file exists $tmpfile_small]} {
        file rename -force $tmpfile_small $imgfile_small
    }
}

proc refetch_images {} {
    set image_root [file dirname [storage_root]]/weather
    if {![file exists $image_root]} {
        file mkdir $image_root
    }

    if {![should_update]} {
        return
    }

    set ts [set_update_timestamp $image_root]

    foreach level {1 3} {
        foreach img [all_images] {
            if {![fetch_if_needed $image_root $ts $level $img]} {
                return
            }
        }
    }

    # At this point, we have already downloaded all updated
    # images, but they may still be in ${level}_${num}_tmp.jpg
    foreach level {1 3} {
        foreach img [all_images] {
            rename_if_needed $image_root $ts $level $img
        }
    }
}


refetch_images
