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

# 6park forum index
#
package require ncgi

proc doit {} {
    global env
    set src http://www.cool18.com/bbs4/

    if {[info exists env(REQUEST_URI)] && [regexp {ref=(.*)} $env(REQUEST_URI) dummy ref]} {
        set src [ncgi::decode $ref]
    }

    set iphone 0
    catch {
        if {[regexp iPhone $env(HTTP_USER_AGENT)]} {
            set iphone 1
        }
    }

    set data [wget $src gb2312]

    set head "<html><head><META HTTP-EQUIV=\"content-type\" CONTENT=\"text/html; charset=utf-8\"></head><body>"


    # (1) if article, rewrite the body
    if {[regexp "act=threadview" $src]} {
        regsub {.*<!--bodybegin-->} $data "" data
        regsub -all "<\[aA\] href=http://list.6park.com/parks/out.php\[^\n\]*>" $data "" data
        regsub -all "<\[aA\] href=\"http://list.6park.com/parks/out.php\[^\n\]*>" $data "" data
        regsub -all "<\[aA\] href=\"http://web.6park.com/bid\[^\n\]*>" $data "" data

        regsub -all sex $data "" data

        regsub -all \r $data "" data
        set wsn "\[\t\r\n \]*"
        set ws  "\[\t\u3000 \]*"
        set pat "^$wsn<pre>(.*)<!--bodyend-->$wsn</pre>"
        if {[regexp $pat $data dummy body]} {
            regsub $pat $data "" data

            regsub -all "\n$ws\n+$ws" $body "<p>\n\n\u3000" body
        
            if {$iphone} {
                set body "<font size=+4>$body</font>"
            }
            set data $body$data
        }
    }
    
    # (2) for all pages, rewrite the links
    set pat "href=\"index.php.(\[^\"\]+)"
    while {[regexp $pat $data dummy target]} {
        set encoded ""
        catch {set encoded [ncgi::encode http://www.cool18.com/bbs4/index.php?$target]}
        regsub $pat $data "href=\"/cgi-bin/6parkidx.cgi?ref=$encoded" data
    }
    regsub -all "<\[aA\] href=http://list.6park.com/parks/out.php\[^\n\]*>" $data "" data
    regsub -all "<\[aA\] href=\"http://list.6park.com/parks/out.php\[^\n\]*>" $data "" data
    regsub -all "<\[aA\] href=\"http://web.6park.com/bid\[^\n\]*>" $data "" data

    regsub -all sex $data "" data
    regsub -all <img $data "<imgxx" data

    regsub -all "<table width=\"998px\"" $data "<table  width=\"100%\"" data
    regsub -all "<table width=" $data "<table nowidth=" data

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
