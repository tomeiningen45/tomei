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

proc main {} {
    global env

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
        set pwd [pwd]
        cd $f
        set list [lsort -dict [glob -nocomplain *]]
        cd $pwd

        puts "<h2>[string range $f $rootlen end]</h2>"
        puts "<li><a href=$me?v=$parent>PARENT</a>"
        for {set i 0} {$i < 2} {incr i} {
            puts <hr>
            foreach sub $list {
                #puts stderr -->$sub
                set sub [file join $f $sub]
                set q [string range $sub $rootlen end]
                set ext [string tolower [file ext $sub]]
                if {($i == 0 && [file isdir $sub]) ||
                    ($i == 1 && ($ext  == ".mp4" || $ext == ".m4v"))} {
                    if {[file isdir $sub] && [regexp {EyeTV/} $sub]} {
                        if {[glob -nocomplain $sub/*.m4v] == ""} {
                            continue
                        }
                    }
                    set name [file tail $q]
                    if {[file isfile $sub]} {
                        #puts stderr ===$name==[string length $name]
                        regsub {[.]mp4$} $name "" name
                        regsub {[.]m4v$} $name "" name
                        regsub {[.]f4v$} $name "" name
                        regsub {[.]flv$} $name "" name
                    }
                    puts "<li><a href='$me?v=[_Url_Encode $q]'>$name</a>"
                }
            }
        }
    } else {
        set file http://$host/videos
        foreach p [file split $orig] {
            set p [_Url_Encode $p]
            regsub -all {[+]} $p %20 p
            append file /$p
        }
        #puts stderr $file
        puts "<body bgcolor=000000>"
        puts "<video src='$file' width='100%' height='100%' controls autoplay>"
    }
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