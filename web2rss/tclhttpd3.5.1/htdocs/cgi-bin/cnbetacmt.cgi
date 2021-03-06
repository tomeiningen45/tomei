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

# This is for reading articles on cnbeta
#
package require ncgi

proc doit {} {
    global env

    set postdata {csrf_token=4183443fd758382a63b39c3f936a20740acd448a&op=1%2C484233%2C50312}
    set refer 484233
    set elapsed1 0
    set elapsed2 0

    if {[info exists env(REQUEST_URI)] && [regexp {ref=(.*)} $env(REQUEST_URI) dummy ref]} {
        set start [clock seconds]
        set refer [ncgi::decode $ref]
        set data [wget http://www.cnbeta.com/articles/$refer.htm]
        set elapsed1 [expr [clock seconds] - $start]

        set token ""
        regexp "TOKEN:\"(\[^\"\]+)" $data dummy token
        set sid ""
        regexp {SID:"([a-f0-9]+)"} $data dummy sid
        set sn ""
        regexp {SN:"([a-f0-9]+)"} $data dummy sn

        set postdata "csrf_token=${token}&op=1%2C${sid}%2C${sn}"
    }

    set iphone 0
    catch {
        if {[regexp iPhone $env(HTTP_USER_AGENT)]} {
            set iphone 1
        }
    }

    set hdr {
        POST /cmt HTTP/1.1
        Accept: application/json, text/javascript, */*; q=0.01
        Content-Type: application/x-www-form-urlencoded; charset=UTF-8
        Origin: http: //www.cnbeta.com
        Host: www.cnbeta.com
        Referer: http: //www.cnbeta.com/articles/REFE.htm
        User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.116 Safari/537.36
        X-Requested-With: XMLHttpRequest
        Content-Length: LENN
    }

    regsub REFE $hdr $refer hdr
    regsub LENN $hdr [string length $postdata] hdr

    set hdr [string trim $hdr]
    regsub -all " *\n +" $hdr "\n" hdr

    set start [clock seconds]
    set fd [socket www.cnbeta.com 80]
    puts $fd $hdr
    puts $fd ""
    puts -nonewline $fd $postdata
    flush $fd
    set data [read $fd]
    close $fd
    set elapsed2 [expr [clock seconds] - $start]

    set head "<html><head><META HTTP-EQUIV=\"content-type\" CONTENT=\"text/html; charset=utf-8\"></head><body>"

    regsub {.*"cmntstore":} $data "" data
    regsub {,"comment_num":.*} $data "" data

    regsub -all {"date":} $data \ufff0 data

    set list ""
    set n 0
    foreach item [split $data \ufff0] {
        set score 0
        regexp {"score":([0-9]+)} $item dummy score

        if {[regexp {"comment":"([^\"]+)"} $item dummy comment]} {
            incr n
            set comment [subst -novariables -nocommands $comment]
            regsub -all "\n" $comment "<br>" comment
            lappend list [list $score $n $comment]
        }
    }

    proc comp {a b} {
        set x [lindex $a 0]
        set y [lindex $b 0]

        if {$x > $y} {
            return 1
        } elseif {$x < $y} {
            return -1
        } else {
            set x [lindex $a 1]
            set y [lindex $b 1]
            if {$x > $y} {
                return 1
            } elseif {$x < $y} {
                return -1
            } else {
                return 0
            }
        }
    }

    if {$iphone} {
        set f0 "<font size=+4>"
        set f1 "</font>"
    } else {
        set f0 ""
        set f1 ""
    }
    set out "<table width=100% borderwidth=2 cellpadding=4>"
    foreach item [lsort -decreasing -command comp $list] {
        set a [lindex $item 0]
        set b [lindex $item 1]
        set c [lindex $item 2]
        append out "<tr>"
        append out "<td style='white-space: nowrap; text-align:right;' valign=top>${f0}$b\u697c${f1}</td>"
        append out "<td style='white-space: nowrap; text-align:right;' valign=top>${f0}\[$a\u5206\]${f1}</td>"
        append out "<td width='99%' valign=top bgcolor='#e0e0ff'>${f0}$c${f1}</td>"
        append out "</tr>"
    }
    append out "</table>"
   #set data "$out<p>postdata=$postdata<br>time1=$elapsed1, time2=$elapsed2"
    set data "$out<p>time1=$elapsed1, time2=$elapsed2"

    return $data
}

source [file dirname [info script]]/lib.tcl
