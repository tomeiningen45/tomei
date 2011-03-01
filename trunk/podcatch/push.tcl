# Push the new MP3 files onto Android phone using ADB.

if {[info exists env(ADBPATH)]} {
    set ADB $env(ADBPATH)
} else {
    set ADB adb
}

proc doit {} {
    global ADB

    set text ""
    catch {
        set text [string trim [exec $ADB shell ls /sdcard/pushme]]
    }
    if {"$text" != "/sdcard/pushme"} {
        puts "Device not connected. Skipped: $text"
        return
    }

    set files ""

    catch {
        set files [exec $ADB shell ls /sdcard/Music]
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


