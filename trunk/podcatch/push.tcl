# Push the new MP3 files onto Android phone using ADB.

if {[info exists env(ADBPATH)]} {
    set ADB $env(ADBPATH)
} else {
    set ADB adb
}

proc hash {name} {
    set num 0xf1234567
    foreach c [split $name ""] {
        set n 0
        scan $c %c n
        #puts $c==$n
        set num [expr ($num << 5) + $num + $n]
    }
    return [format %08x $num]
}

proc backup_itunes_lib {} {
    global env
    set dir "$env(USERPROFILE)/My Documents/My Music/iTunes"
    set file "$dir/iTunes Music Library.xml"

    set back z:/iTunes/catch
    file mkdir $back
    file copy -force $file $back/lib.tmp
    file rename -force $back/lib.tmp $back/lib.xml
}

proc doit {} {
    global ADB

    backup_itunes_lib

    puts "====checking space ..."
    catch {
        exec $ADB shell df /sdcard  2>@ stderr >@ stdout
    }
    puts "====checking space ... done"

    set text ""
    catch {
        set text [string trim [exec $ADB shell ls /sdcard/pushme 2>@ stderr]]
    }
    if {"$text" != "/sdcard/pushme"} {
        puts "Device not connected. Skipped: $text"
        return
    }

    set files ""

    catch {
        set files [exec $ADB shell ls /sdcard/Music 2>@ stderr]
    }

    foreach f $files {
        set has($f) 1
    }

    set total 0
    foreach f [glob -nocomplain nhk/mp3/*.mp3 voiceblog/voiceblog/*.mp3] {
        set t [file tail $f]
        if {![info exists has($t)]} {
            set ftime [file mtime $f]
            set now   [clock seconds]

            if {$now - $ftime < 7 * 86400} {
                puts "New but not too old:  $f"
                set size [file size $f]
                incr total $size

                exec $ADB push $f /sdcard/Music 2>@ stderr >@ stdout
            }
        }
    }

    if {0} {

    set files ""

    catch {
        set files [exec $ADB shell ls /sdcard/Podcasts]
    }

    foreach f $files {
        set has($f) 1
    }

    foreach f [glob -nocomplain z:/iTunes/Podcasts/*/*.mp3] {
        regsub .*iTunes/Podcasts/ $f "" t
        regsub / $t _ t
        set t [hash $t].mp3
        if {![info exists has($t)]} {
            set ftime [file mtime $f]
            set now   [clock seconds]

            if {$now - $ftime < 7 * 86400} {
                puts "New but not too old: $t = $f"
                set size [file size $f]
                incr total $size

                set tmp c:/tmp/push.tcl.mp3
                file copy $f $tmp
                exec $ADB push $tmp /sdcard/Podcasts/$t 2>@ stderr >@ stdout
                file delete $tmp                
            }
        }
    }

    }

    if {$total > 0} {
        puts "Updating media scanner"
        exec $ADB shell am broadcast -a android.intent.action.MEDIA_MOUNTED --ez read-only false -d file:///sdcard 2>@ stderr >@ stdout
    }
    puts "Total new files = [expr round($total / 1024 / 1024.0)] MB"
}

while 1 {
    puts "===================== trying [exec date]===="
    doit
    puts "===================== sleeping [exec date]===="
    after [expr 1000 * 60 * 5]
}


