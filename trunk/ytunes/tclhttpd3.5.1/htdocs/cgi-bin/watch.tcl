#!/bin/sh
# \
if [ -e /usr/bin/tclsh ]; then exec /usr/bin/tclsh "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/local/bin/tclsh8.4 ]; then exec /usr/local/bin/tclsh8.4 "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/local/bin/tclsh8.3 ]; then exec /usr/local/bin/tclsh8.3 "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/bin/tclsh8.4 ]; then exec /usr/bin/tclsh8.4 "$0" ${1+"$@"} ; fi
# \
exec tclsh "$0" ${1+"$@"}

# Need this: sudo apt-get install tcl tcllib
#
# This script serves videos on HTTP for ipad, etc. It just creates the
# HTML pages. Note that the video themselves need to be served by
# apache, because Tcl HTTP server cannot do progressive HTTP download.

source [file dirname [info script]]/../../lib/url.tcl
package require uri

#foreach i [array names env] {
#    puts stderr "$i = $env($i)"
#}

set config(is_ipad) 0

catch {
    set agent $env(HTTP_USER_AGENT)
    if {[regexp iPad $agent]} {
	set config(is_ipad) 1
	#puts stderr ipad
    }
}

proc video_size {file} {
    set width 640
    set height 480

    if {[catch {
        set out [exec ffmpeg -i $file]
    } err]} {
	set out $err
    }

    #puts stderr $out

    if {[regexp "Stream\[^\n\]*: Video:\[^\n\]*, (\[0-9\]+)x(\[0-9\]+)" $out dummy width height]} {
	return [list $width $height]
    } else {
	return {640 480}
    }
}


proc remove_youtube_suffix {name} {
    set p {[A-Za-z0-9_-]}
    set p $p$p$p$p$p$p$p$p$p
    set p (.*)\[-\]($p)

    if {[regexp $p $name dummy stem tail]} {
        set tail [string range $tail 1 end]
        if {[regexp {[0-9]} $tail] && 
            [string toupper $tail] != $tail &&
            [string tolower $tail] != $tail} {
            # If we have mixed cases here it's probably
            # a Youtube ID
            return $stem
        }
    }
    return $name
}

proc main {} {
    global env config

    #puts stderr $env(QUERY_STRING) 
    set f ""
    catch {
        regexp {v=([^&]+)} $env(QUERY_STRING) dummy f
        set f [Url_Decode $f]
        if {[file exists /opt/local/apache2/htdocs/here]} {
            # this is my mac -- must use utf-8 file name
            set f [encoding convertfrom utf-8 $f]
        }
    }

    if {"$f" == "/"} {
        set f ""
    }
    if {"$f" == "."} {
        set f ""
    }
    
    if {[file exists /opt/local/apache2/htdocs/here]} {
        set root /opt/local/apache2/htdocs/videos
        set host 192.168.2.80
    } else {
        set root /var/www/videos
        set host 192.168.2.106
    }

    catch {
        set host $env(HTTP_HOST)
        regsub :.* $host "" host
    }

    set rootlen [expr [string length $root] + 1]

    set orig $f
    set parent [file dirname $f]

    set f [file join $root $f]
    if {![file exists $f]} {
        set f $root
        set parent /
        set orig /
    }

    set me "/cgi-bin/watch.tcl"

    puts "Content-Type: text/html"
    puts ""
    puts {<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=640, initial-scale=1.0"/>  
</head>
    }


    #puts stderr f=$f

    if {[file isdir $f]} {
        puts "<table width = 100%><tr>"
        set pwd [pwd]
        cd $f
        set list [lsort -dict [glob -nocomplain *]]
        cd $pwd

        set count 0

	if {$config(is_ipad)} {
	    set COLS 5
	    set THUMBW 150
	} else {
	    set COLS 3
	    set THUMBW 256
	}
	set colw [expr 100 / $COLS]
        puts "<h2>[string range $f $rootlen end]</h2>"
        puts "<li><a href=$me?v=$parent>PARENT</a>"
        for {set i 0} {$i < 2} {incr i} {
            puts <hr>
            foreach sub $list {
                #puts stderr -->$sub
                set sub [file join $f $sub]
                set q [string range $sub $rootlen end]
                set ext [string tolower [file ext $sub]]

		if {[file isdir $sub] && [regexp {EyeTV/.*.eyetvsched$} $sub]} {
		    continue
		}

		# Special case: Martha Speaks - Martha and Skits_ Martha Plays a Part.eyetv/0000000014fdd2c1.iPhone.m4v
		# -> make this appear as if in current directory
		set name ""
		if {[file isdir $sub] && [regexp {.eyetv$} $sub]} {
		    set grandkids [glob -nocomplain $sub/*.m4v]
		    if {[llength $grandkids] == 1} {
			if {[regexp {/busy_} $grandkids]} {
			    continue
			}
			set sub [lindex $grandkids 0]
			append q /[file tail $sub]
			set name $sub
			regsub {[.]eyetv/.*} $name "" name
			set name [file tail $name]
			set ext .m4v
			regsub { *[-]} $name : name
		    } elseif {[llength $grandkids] == 0} {
			# EyeTV has not exported iPhone/iPad m4v file for this recording
			continue
		    }
		}

                if {($i == 0 && [file isdir $sub]) ||
                    ($i == 1 && ($ext  == ".mp4" || $ext == ".m4v"))} {
                    #if {[file isdir $sub] && [regexp {EyeTV/} $sub]} {
                    #    if {[glob -nocomplain $sub/*.m4v] == ""} {
                    #        continue
                    #    }
                    #}

		    if {$name == ""} {
			set name [file tail $q]
		    }
                    if {[file isfile $sub]} {
                        #puts stderr ===$name==[string length $name]
                        regsub {[.]mp4$} $name "" name
                        regsub {[.]m4v$} $name "" name
                        regsub {[.]f4v$} $name "" name
                        regsub {[.]flv$} $name "" name
                        regsub -all _+ $name " " name
                        regsub -all {[-]+} $name " " name

                        set name [remove_youtube_suffix $name]

                        set thumb [file dirname $sub]/.[file tail $sub].jpg
                        if {[file exists $thumb]} {
                            set thumbq [string range $thumb $rootlen end]
                            set thumbq [get_video_or_thumbnail_url $host $thumbq]
                            #puts stderr $thumbq
                        } else {
                            set thumbq /defaultThumbnail.png
                        }
                        set img "<img src=$thumbq width='${THUMBW}px'>"
                    } else {
                        set img "<img src=/videoFolder.png width='${THUMBW}px'>"
                    }

		    set name "${img}<br><span style='WIDTH:${THUMBW}px'>$name"

                    puts "<td width=${colw}% valign=top><a href='$me?v=[_Url_Encode $q]'>$name</a><br>&nbsp;</td>"
                    incr count
                    if {($count % $COLS) == 0} {
                        puts "</tr><tr><td colspan=$COLS><hr></td></tr><tr>"
                    }
                }
            }
        }
        puts "</tr></table>"
    } else {
	set list [video_size $f]
	set w [lindex $list 0]
	set h [lindex $list 1]

	puts stderr "Size = $list"

        set file http://$host/videos
        foreach p [file split $orig] {
            set p [_Url_Encode $p]
            regsub -all {[+]} $p %20 p
            append file /$p
        }
        #puts stderr $file
	if {$config(is_ipad)} {
	    puts "Size = $w x $h<br>"
	    if {[expr $w / $h.0] > 1.1} {
		set h [expr int($h * 800.0 / $w)]
		set w 800
	    }
	    puts "<video src='$file' width='${w}px' height='${h}px' controls autoplay><br>"
	} else {
	    puts "<body bgcolor=000000>"
	    puts "<video src='$file' width='100%' height='100%' controls autoplay>"
	}
    }
}

# The full path is /var/www/videos/$q
proc get_video_or_thumbnail_url {host q} {
    set url http://$host/videos
    foreach p [file split $q] {
        set p [_Url_Encode $p]
        regsub -all {[+]} $p %20 p
        regsub -all {[ ]} $p %20 p
        append url /$p
    }
    return $url
}

proc _Url_Encode {x} {
    if {[catch {
        set x [Url_Encode $x]
    }]} {
        set x [my_url_encode $x]
    }
    return $x
}

proc my_url_encode {input} {
    set result ""
    foreach c [split $input ""] {
        set u [encoding convertto utf-8 $c]
        if {[regexp {^[a-zA-Z0-9/.]$} $u]} {
            append result $c
        } else {
            foreach b [split $u ""] {
                scan $b %c v
                append result %[format %2x $v]
            }
        }
    }
    return $result
}


if 0 {
    foreach n [array names env] {
        puts stderr $n=$env($n)
    }
}

main
exit 0
