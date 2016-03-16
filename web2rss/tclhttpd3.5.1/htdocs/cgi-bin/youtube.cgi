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
    set src https://www.youtube.com/feeds/videos.xml?playlist_id=PL84AA3B15430BD29A

    if {[info exists env(REQUEST_URI)] && [regexp {ref=(.*)} $env(REQUEST_URI) dummy ref]} {
        set src [ncgi::decode $ref]
    }

    set data [wget $src]
    set date [clock format [clock seconds]]
    regsub -all {<published>[^<]+} $data "<published>$date" data
    regsub -all {<updated>[^<]+} $data "<updated>$date" data


    regsub {</yt:playlistId>} $data "</yt:playlistId><yt:ref>ref=[ncgi::encode $src]</yt:ref>" data
    return $data
}

set isfeed 1
source [file dirname [info script]]/lib.tcl
