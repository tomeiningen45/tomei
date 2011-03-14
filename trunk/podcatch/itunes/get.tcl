# This script runs on Linux. It copies the contents of ~/iTunes/Podcasts (which is saved to
# by iTunes running on Windows -- iTunes is configured to write the podcasts to that
# directory via SAMBA). During copying, it updates the MP3 tags using the same rules
# as ../voiceblog/voiceblog_get.tcl
#
# Windows also runs ../push.tcl continuously. It will copy the 
# $env(USERPROFILE)/My Documents/My Music/iTunes/iTunes Music Library.xml file
# onto ~/iTunes/catch/lib.xml to be used by this script.

# sudo apt-get install tcllib
# sudo apt-get install lame faad
#

#package require uri
#package require uri::urn

source [file dirname [info script]]/../voiceblog/all_common.tcl

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
    global env
    set fd [open $xmlfile r]
    fconfigure $fd -encoding utf-8
    set data [read $fd]
    fconfigure stdout -encoding utf-8
    set HOME $env(HOME)

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
        set origfilename [file tail $file]
        set file [unquote $file]
        set filename [file tail $file]
        set dirname  [file tail [file dir $file]]

        set ext [file ext $filename]
        set origext $ext

        if {"$ext" == ".mp3"} {
            # do nothing
        } elseif {"$ext" == ".m4a"} {
            set ext .mp3
        } elseif {"$ext" == ".mp4"} {
            # do nothing
        } elseif {"$ext" == ".m4v"} {
            # do nothing
        } else {
            puts "Unknown file type $ext: ignore $file"
            continue
        }
        
        set dstname $date-[hash $dirname]-[hash $filename]$ext
  
        #puts $dirname/$filename/-$date-$name-$dstname

        if {[info exists exists($dstname)]} {
            puts "++++++ HASH CONFLICT -> FILE IGNORED $dirname/$filename"
        }
        set exists($dstname) 1

        if {"$ext" == ".mp4" || "$ext" == ".m4v"} {
            set dstdir  $HOME/iTunes/catch/videos
            continue
        } else {
            set dstdir  $HOME/iTunes/catch/tracks
        }
        set srcpath $HOME/iTunes/Podcasts/$dirname/$filename
        set dstpath $dstdir/$dstname

        #if {[regexp {.mp[34]$} $srcpath]} {
        #    continue
        #}

        if {![file exists $srcpath]} {
            set srcpath $HOME/iTunes/catch0/tracks/[file root $dstname]$origext
        }

        if {![file exists $dstpath]} {
            puts "Copying $dirname/$filename $srcpath"
            file mkdir $dstdir

            set sec [clock scan 20$date]
            set dateid [dateid $sec]
            set tmpfile $HOME/iTunes/catch/tmp$ext

            if {"$ext" == ".mp3"} {
                if {"$origext" == ".mp3"} {
                    file copy -force $srcpath $tmpfile
                } else {
                    set wav $HOME/iTunes/catch/tmp.wav
                    catch {
                        puts "Running faad"
                        exec faad -q -o $wav $srcpath \
                            2>@ stderr >@ stdout
                    }
                    catch {
                        puts "Running lame"
                        exec nice lame -b 64 -S -m m -f $wav -o $tmpfile \
                            2>@ stderr >@ stdout
                    }
                    file delete $wav
                }
                if {![file exists $tmpfile]} {
                    puts "Not supported format??"
                    continue
                }

                set sec [clock scan 20$date]
                set dateid [dateid $sec]

                set title "$dateid $name"
                set artist "$date $dirname"
                set album "IT $dirname"
                set genre "IT"

                set mp3 $tmpfile
                exec id3v2 -D $mp3 2>@ stderr >@ stdout
                exec eyeD3 --set-encoding=utf16-LE \
                    -G $genre -a $artist -A $album \
                    -t $title $mp3 2>@ stderr >@ stdout
            } elseif {"$ext" == ".mp4" || "$ext" == ".m4v"} {
                file copy -force $srcpath $tmpfile
            } else {
                continue
            }

            file mtime $tmpfile $sec
            file rename -force $tmpfile $dstpath

            #exit
        }
    }


    close $fd
}

while 1 {
    puts "===================== trying [exec date]===="
    get_lib ~/iTunes/catch/lib.xml
    puts "===================== sleeping [exec date]===="
    after [expr 1000 * 60 * 5]
}




