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
    set out ""
    set prefix ""

    foreach item [split $data \ufff0] {
        set score 0
        regexp {"score":([0-9]+)} $item dummy score

        if {[regexp {"comment":"([^\"]+)"} $item dummy comment]} {
            set comment [subst $comment]
            regsub -all "\n" $comment "<br>" comment
            append out $prefix
            append out "\[$score\] $comment"
            set prefix "<hr>\n"
        }
    }

    set data "$out<p>postdata=$postdata<br>time1=$elapsed1, time2=$elapsed2"
    if {$iphone} {
        set data "<font size=+4>$data</font>"
    }

    set width 740
    if {$iphone} {
        set width 250
    }

    set data "<table width=100% border=0 align=center cellspacing=0 cellpadding=5><tr><td>$data</td></tr></table>"

    return "$head$data</body></html>"
}

source [file dirname [info script]]/lib.tcl
