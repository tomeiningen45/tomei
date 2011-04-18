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
    global first

    backup_itunes_lib

    if {$first} {
        puts "====checking space ..."
        catch {
            exec $ADB shell df /sdcard  2> NUL >@ stdout
        }
        puts "====checking space ... done"
    }

    set text ""
    catch {
        set text [string trim [exec $ADB shell ls /sdcard/pushme 2> NUL]]
    }
    if {"$text" != "/sdcard/pushme"} {
        if {$first} {
            puts "Device not connected. Skipped: $text"
        }
        return
    }

    set files ""

    catch {
        set files [exec $ADB shell ls /sdcard/Music 2>@ stderr]
    }

    foreach f $files {
        set has($f) 1
    }

    set now [clock seconds]

    foreach f [glob -nocomplain nhk/mp3/*.mp3] {
        set ftime [file mtime $f]

        if {$now - $ftime > 10 * 86400} {
            puts "Delete old NHK $f"
            file delete $f
        }
    }

    foreach f [glob -nocomplain voiceblog/voiceblog/*tachiyomist*.mp3] {
        set ftime [file mtime $f]

        if {$now - $ftime > 30 * 86400} {
            puts "Delete old tachiyomist $f"
            file delete $f
        }
    }

    #uncomment for testing deleteing (or if you run out of space)
    #set nocopy 1

    set deleted 0
    set total 0
    foreach f [glob -nocomplain nhk/mp3/*.mp3 voiceblog/voiceblog/*.mp3] {
        set t [file tail $f]
        set seenonpc($t) 1
        if {![info exists has($t)] && ![info exists nocopy]} {
            set ftime [file mtime $f]
            set now   [clock seconds]

            if {$now - $ftime < 7 * 86400} {
                set size [file size $f]
                puts "New but not too old:  $f $size"
                incr total $size

                catch {exec $ADB push $f /sdcard/Music/tmp 2>@ stderr >@ stdout}
                catch {exec $ADB shell mv /sdcard/Music/tmp /sdcard/Music/$t 2>@ stderr >@ stdout}
            }
        }
    }

    foreach f [array names has] {
        if {[regexp {[-]news[-].....mp3} $f] ||
            [regexp {[-]tachiyomist[-]} $f]} {
            if {![info exists seenonpc($f)]} {
                set deleted 1
                puts "Delete $f"
                catch {exec $ADB shell rm /sdcard/Music/$f 2>@ stderr >@ stdout}
            }
        }
    }

    #-------------------------------------------------------------------------------
    catch {unset has}
    catch {unset seenonpc}

    set files ""

    catch {
        set files [exec $ADB shell ls /sdcard/Pod]
    }

    foreach f $files {
        set has($f) 1
    }

    foreach f [glob -nocomplain z:/iTunes/catch/tracks/*] {
        set t [file tail $f]
        set seenonpc($t) 1
        if {![info exists has($t)] && ![info exists nocopy]} {
            set ftime [file mtime $f]
            set now   [clock seconds]

            if {1 || ($now - $ftime < 7 * 86400)} {
                set size [file size $f]
                puts "New but not too old: ($size) $t = $f"
                incr total $size
                catch {exec $ADB push $f /sdcard/Pod/tmp 2>@ stderr >@ stdout}
                catch {exec $ADB shell mv /sdcard/Pod/tmp /sdcard/Pod/$t 2>@ stderr >@ stdout}
            }
        }
    }

    foreach f [array names has] {
        if {![info exists seenonpc($f)]} {
            set deleted 1
            puts "Delete $f"
            catch {exec $ADB shell rm /sdcard/Pod/$f 2>@ stderr >@ stdout}
        }
    }


    if {$total > 0 || $deleted > 0} {
        puts "Updating media scanner"
        exec $ADB shell am broadcast -a android.intent.action.MEDIA_MOUNTED --ez read-only false -d file:///sdcard 2>@ stderr >@ stdout
    }
    if {$total > 0} {
        puts "Total new files = [expr round($total / 1024 / 1024.0)] MB [exec date]"
    }
}

set first 1
while 1 {
    if {$first} {
        puts "===================== trying [exec date]===="
    }
    doit
    if {$first} {
        puts "===================== sleeping [exec date]===="
    }
    after [expr 1000 * 60 * 5]
    set first 0
}


