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

proc hash {name} {
    set num 0xf1234567
    foreach c [split $name ""] {
        set n 0
        scan $c %c n
        #puts $c==$n
        set num [expr ($num << 5) + $num + $n]
    }
    return [format %08x $num]
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
        if {![regexp {<key>Release Date</key><date>20(..-..-..)} $part dummy date]} {
            continue
        }
        if {![regexp {<key>Name</key><string>([^<]+)} $part dummy name]} {
            continue
        }
        regsub -all -- - $date "" date
        set file [unquote $file]
        set filename [file tail $file]
        set dirname  [file tail [file dir $file]]
        
        set dstname $date-[hash $dirname]-[hash $filename][file ext $filename]

        #puts $dirname/$filename/-$date-$name-$dstname

        if {[info exists exists($dstname)]} {
            puts "++++++ HASH CONFLICT -> FILE IGNORED $dirname/$filename"
        }
        set exists($dstname) 1

        set dstdir  ~/iTunes/catch/tracks
        set srcpath ~/iTunes/Podcasts/$dirname/$filename
        set dstpath $dstdir/$dstname

        #if {[regexp {.mp3$} $srcpath]} {
        #    continue
        #}

        if {![file exists $dstpath]} {
            puts "Copying $dirname/$filename"
            file mkdir $dstdir
            file copy -force $srcpath $dstpath

            set title $name
            set artist "$date $dirname"
            set album "IT $dirname"
            set genre "IT"

            set mp3 [glob $dstpath]
            exec id3v2 -D $mp3 2>@ stderr >@ stdout
            exec eyeD3 --set-encoding=utf16-LE \
                -G $genre -a $artist -A $album \
                -t $title $mp3 2>@ stderr >@ stdout

            set sec [clock scan 20$date]
            file mtime $mp3 $sec
        }
        #exit
    }


    close $fd
}

while 1 {
    puts "===================== trying [exec date]===="
    get_lib ~/iTunes/catch/lib.xml
    puts "===================== sleeping [exec date]===="
    after [expr 1000 * 60 * 5]
}




