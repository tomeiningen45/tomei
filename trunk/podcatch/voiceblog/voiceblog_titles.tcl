source [file dirname [info script]]/voiceblog_common.tcl

set default_channels {
    tabitabi
    tachiyomist
    otamama842
    caramellogic
    hotcast
    ikebukuronow
    pillowtalk
    girls
    nippon
    jijyoradio
    tin25000
    montecarlo
    bosmoru
    askw1974
    chunen
    udochuru
    katsuhiro
    gekiura
    seishun-cho
}
#    madge   pink-away
#
#    dennounews_podcast
#    strawberrydrops
#    mote
#     mayo-love
#    tokyo-pod
#    udochuru
#     bukuro24

set cfg(numtitles) 10000
set cfg(depth)     1
set cfg(channels)  $default_channels

proc parse_args {argv} {
    global cfg

    if {[llength $argv] >= 1} {
	set cfg(numtitles) [lindex $argv 0]
    }
    if {[llength $argv] >= 2} {
	set cfg(depth) [lindex $argv 1]
    }
    if {[llength $argv] >= 3} {
	set cfg(channels) [lrange $argv 2 end]
    }
}

proc voiceblog_getmonth {delta} {
    set time  [clock seconds]
    set year  [clock format $time -format %Y]
    set month [clock format $time -format %m]
    regsub ^0 $month "" month
    set month [expr $month - $delta]

    while {$month <= 0} {
	incr year -1
	incr month 12
    }

    return [format %d%02d $year $month]
}

proc split_regexp {str regexp} {
    regsub -all $regexp $str \uffff str
    return [split $str \uffff]
}

proc get_index_for_month {chan url month} {
    global cfg env

    if {[info exists env(VOICEBLOG_VERBOSE)]} {
	puts stderr ===============$url
    }
    set data [wget $url euc-jp]
    #puts $data
    foreach part [split_regexp $data {<div class="content_box">}] {
	set title ""
	set mp3   ""
	set name ""
	set date ""

	regexp {<a name="([0-9]+)">} $part dummy name
	regexp {<div class="content_title">([^<]+)} $part dummy title
	regexp {<a href="([^\"]+[.]mp3)"} $part dummy mp3
	regexp {<div class="date">([^<]+),} $part dummy date

	if {"$mp3" == ""} {
	    regexp {[?]url=([^\"]+[.]mp3)} $part dummy mp3
	}
	#puts stderr $mp3--$title--$name--$date

	#puts $date
	if {[catch {
	    set date [clock scan $date]
	    set date [clock format $date -format %y%m%d]
	}]} {
	    continue
	}

	set title [string trim $title]
	if {$name != "" && $title != "" && $mp3 != ""} {
	    set filename voiceblog/$date-$chan-[file tail $mp3]
	    #puts stderr $filename
	    if {![file exists $filename] || [info exists env(VIOCEBLOG_RELOAD)]} {
		puts http://www.voiceblog.jp/$chan/$name.html
		incr cfg(numtitles) -1
		if {[info exists env(VOICEBLOG_VERBOSE)]} {
		    puts stderr "$filename"
		}
	    } else {
		if {[info exists env(VOICEBLOG_VERBOSE)]} {
		    puts stderr "$filename == ALREADY DONE"
		}
	    }
	}

	if {$cfg(numtitles) <= 0} {
	    break
	}
    }

    if {![regexp \u524d\u6708 $data]} {
	# zengetsu
	return 0
    } else {
	return 1
    }
}

proc get_index {chan} {
    global cfg env
    set start 0

    if {[info exists env(VOICEBLOG_STARTMONTH)]} {
	set start $env(VOICEBLOG_STARTMONTH)
    }

    for {set i 0} {$i < $cfg(depth)} {incr i} {
	set month [voiceblog_getmonth [expr $i + $start]]
	set url http://www.voiceblog.jp/$chan/m$month.html
        if {![get_index_for_month $chan $url $month]} {
	    break
	}

	if {$cfg(numtitles) <= 0} {
	    break
	}
    }
}

proc main {argv} {
    global cfg

    parse_args $argv
    foreach chan $cfg(channels) {
	get_index $chan
    }
}

set verbose 1
main $argv