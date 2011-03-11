# This script runs on Linux. It copies the contents of ~/iTunes/Podcasts (which is saved to
# by iTunes running on Windows -- iTunes is configured to write the podcasts to that
# directory via SAMBA). During copying, it updates the MP3 tags using the same rules
# as ../voiceblog/voiceblog_get.tcl
#
# Windows also runs ../push.tcl continuously. It will copy the 
# $env(USERPROFILE)/My Documents/My Music/iTunes/iTunes Music Library.xml file
# onto ~/iTunes/catch/lib.xml to be used by this script.

# sudo apt-get install tcllib
#

package require uri
package require uri::urn

proc splitex {data pat} {
    regsub -all $pat $data \uFFFF data
    return [split $data \uFFFF]
}

proc unquote {s} {
    set d ""

    while {[string length $s] > 0} {
        set c [string index $s 0]
        if {"$c" == "%"} {
            append d [binary format c [expr 0x[string index $s 1][string index $s 2]]]
            set s [string range $s 3 end]
        } else {
            append d $c
            set s [string range $s 1 end]
        }
    }

    return [encoding convertfrom utf-8 $d]
}

proc get_lib {xmlfile} {
    set fd [open $xmlfile r]
    fconfigure $fd -encoding utf-8
    set data [read $fd]
    fconfigure stdout -encoding utf-8

    foreach part [splitex $data "<key>Track ID</key>"] {
        if {[string first <key>Name</key> $part] < 0} {
            continue;
        }
        if {![regexp {<key>Location</key><string>([^<]+)} $part dummy file]} {
            continue
        }
        if {![regexp {<key>Release Date</key><date>([^<]+)} $part dummy date]} {
            continue
        }
        puts [unquote $file]
        exit
    }


    close $fd
}

set lib [get_lib ~/iTunes/catch/lib.xml]

puts $lib