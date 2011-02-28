if {[regexp {[-]v} $argv]} {
    set verbose 1
} else {
    set verbose 0
}

regsub {[-]v} $argv "" argv

if {[regexp {[-]n} $argv]} {
    set noaction 1
} else {
    set noaction 0
}

regsub {[-]v} $argv "" argv
regsub {[-]n} $argv "" argv

proc get_double_wide_number {} {
    return [list \
		\uff10 \
		\uff11 \
		\uff12 \
		\uff13 \
		\uff14 \
		\uff15 \
		\uff16 \
		\uff17 \
		\uff18 \
		\uff19]
}

proc replace_double_wide_to_single {text} {
    set list [get_double_wide_number]
    for {set i 0} {$i <= 9} {incr i} {
	regsub -all [lindex $list $i] $text $i text
    }
    return $text
}

proc nocatch {s} {
    uplevel 1 exec $s
}

proc wget {url {encoding shiftjis}} {
    global verbose
    if {$verbose} {
	puts stderr "wget $url"
    }
    puts -nonewline stderr .
    global env


    if {[catch {
	set tmp $env(TEMP)/[pid].wget
    }]} {
	set tmp /tmp/[pid].wget
    }

    set data ""

    file delete $tmp

    catch {
	exec wget -O $tmp $url
    }
    if {[catch {
	set fd [open $tmp r]
	fconfigure $fd -encoding $encoding
	set data [read $fd]
	close $fd
    } err]} {
	puts $err
    }
    catch {
	file delete $tmp
    }

    return $data
}

proc prepare_html_file {file} {
    set head 0
    set num 1

    if {![file exists $file]} {
	set head 1
    } else {
        set fd [open $file r]
	while {![eof $fd]} {
	    set line [gets $fd]
	    if {[regexp {[.]mp3} $line]} {
		incr num
	    }
	}
        close $fd
    }

    set fd [open $file a+]
    if {$head} {
	puts $fd "<title>NHK</title>"
    }
    puts $fd "\[$num\] "
    close $fd
}

proc numtoaz {num {div1 1.0} {div2 1.0}} {
    regsub {^0+} $num "" num
    if {"$num" == ""} {
	set num 0
    }
    set num [expr int($num * $div1 / $div2)]
    return [string index 123456789abcdefghijklmnopqrstuvwxyz $num]
}

proc dateid {sec} {
    set sec [expr $sec - [clock scan 19890101]]
    set chars "0123456789abcdefghijklmnopqrstuvwxyz"
    set num [string length $chars]

    set sec [expr $sec / 60]
    set id ""
    for {set n 0} {$n < 5} {incr n} {
	set x [expr $sec % $num]
	set sec [expr $sec / $num]
	set id "[string index $chars $x]$id"
    }

    return $id

    #append id [numtoaz [clock format $sec -format %m]]
    #append id [numtoaz [clock format $sec -format %d]]
    #append id [numtoaz [clock format $sec -format %H]]
    #append id [numtoaz [clock format $sec -format %M] 25.9 60.1]
    #return $id
}

proc setid3 {mp3 album agency {extra ""}} {
    if {[catch {
	set len [lindex [exec sh -c "(mp3info -x $mp3 2> /dev/null | grep Length) || exit 0"] 1]
	set len [format "%5s" [string trim $len]]

	set sec [file mtime $mp3]
	set weekday [string tolower [string range [clock format $sec -format %a] 0 1]]

	if {"$album" == "VB"} {
	    set filedate [string range [file tail $mp3] 0 5]
            set sec [clock scan 20$filedate]
        }

	set title [dateid $sec]

	if {$extra != ""} {
	    append title " $extra"
	}
	if {"$album" == "VB"} {
	    set genre VB
	    set filedate [string range [file tail $mp3] 0 5]
	    set artist "$filedate $agency  $len"
	} else {
	    set genre News
	    set artist [clock format $sec -format "%m%d$weekday%H:%M $agency$len"]
	}
	set album $album$agency

	#exec id3v2 -g News -a News -A [clock format $sec -format "%m/%d %a"] \
	#    -t $title $mp3 2>@ stderr >@ stdout
	#
	exec id3v2 -D $mp3 2>@ stderr >@ stdout
        #file copy -force $mp3 /tmp/x
	exec eyeD3 --set-encoding=utf16-LE \
	    -G $genre -a $artist -A $album \
	    -t $title $mp3 2>@ stderr >@ stdout
        #catch {
        #    exec mv /tmp/x $mp3
        #}
        catch {
            file mtime $mp3 $sec
        }
    } err]} {
	global errorInfo
	puts "setid3 ERROR: $err"
	puts $errorInfo
    }
}

