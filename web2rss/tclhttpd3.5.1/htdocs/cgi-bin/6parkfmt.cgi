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

# 6park forum chinese article formatting
#
#
package require ncgi

proc doit {} {
    global env

    set src http://www.cool18.com/bbs4/index.php?app=forum&act=threadview&tid=13954277

    if {[info exists env(REQUEST_URI)] && [regexp {ref=(.*)} $env(REQUEST_URI) dummy ref]} {
        set src [ncgi::decode $ref]
    }
    set data [wget $src gb2312]
    set head "<html><head><META HTTP-EQUIV=\"content-type\" CONTENT=\"text/html; charset=utf-8\"></head><body>"

    regsub {.*<!--bodybegin-->} $data "" data
    regsub -all "<\[aA\] href=http://list.6park.com/parks/out.php\[^\n\]*>" $data "" data
    regsub -all "<\[aA\] href=\"http://list.6park.com/parks/out.php\[^\n\]*>" $data "" data
    regsub -all "<\[aA\] href=\"http://web.6park.com/bid\[^\n\]*>" $data "" data

    regsub -all sex $data "" data

    set wsn "\[\t\r\n \]*"
    set ws  "\[\t　 \]*"
    set pat "^$wsn<pre>(.*)<!--bodyend-->$wsn</pre>"
    if {[regexp $pat $data dummy body]} {
        regsub $pat $data "" data

        regsub -all "\n\n+$ws" $body <p>\n\n body
        
        set data $body$data
    }

    if {0} {
        append head <table>
        foreach name [lsort [array names env]] {
            append head "<tr><td>$name</td><td>$env($name)</td></tr>"
        }
        append head </table>
    }
    append head "<a href=$src>ORIG</a><p>"

    return $head$data
}

source [file dirname [info script]]/lib.tcl
