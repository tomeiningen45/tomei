source [file dirname [info script]]/voiceblog_common.tcl

proc voiceblog_get {url} {
    set data [wget $url euc-jp]

    set date ""
    set title ""
    set mp3 ""
    set chan ""
    set blogger "$chan"

    regexp {http://www.voiceblog.jp/([^/]+)} $data dummy chan
    regexp {<div class="content_title">([^<]+)} $data dummy title
    regexp {<a href="([^\"]+[.]mp3)"} $data dummy mp3
    regexp {<div class="date">([^<]+),} $data dummy date
    regexp {ablog_tit">([^<]+)} $data dummt blogger

    if {[regexp tachiyomist $title]} {
        if {[regexp {<div class="content_main">[^>]+>([^>&]+)} $data dummy x]} {
            set title $x
        }
    }

    if {"$mp3" == ""} {
	 regexp {[?]url=([^\"]+[.]mp3)} $data dummy mp3
    }

    set blogger " $blogger"

    if {[catch {
	set date [clock scan $date]
	set date [clock format $date -format %y%m%d]
    }]} {
        return
    }

    set title [string trim $title]
    if {$title != "" && $mp3 != ""} {
	set filename voiceblog/$date-$chan-[file tail $mp3]

	if {![file exists $filename]} {
	    file delete $filename
	    catch {
		exec wget -O $filename $mp3 2>@ stderr >@ stderr
	    }
	}
	setid3 $filename VB $blogger $title
    }
}

proc main {argv} {
    foreach url [lsort $argv] {
	voiceblog_get $url
    }
}

main $argv