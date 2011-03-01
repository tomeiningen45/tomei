# cvlc http://www.nhk.or.jp/r-news/asx/20100627_1_2_20100627145603_noon.asx ––sout \
#    "#transcode{acodec=mp3}:duplicate{dst=std{access=file,mux=raw,dst=\"foo.mp3\"},select=\"novideo\"}" vlc://quit
#
# adb shell am broadcast -a android.intent.action.MEDIA_MOUNTED --ez read-only false -d file:///sdcard
#
# cvlc mms://wm.nhk.or.jp/r-news/20100627220003_1_1_midnight.wma ––sout \
# "demux=dump :demuxdump-file
#
# sudo apt-get install id3v2 eyeD3 vlc-nox mplayer lame
#
# http://www.nhk.or.jp/gr  chikyuu rajio


set test {

    cvlc -vvv mms://wm.nhk.or.jp/r-news/20100627220003_1_1_midnight.wma \
       :mms-caching=0 :demux=dump :demuxdump-file=/tmp/foo.wma


    mplayer -dumpstream mms://www.mysite.com/video.wmv -dumpfile saved-video.wmv
    mplayer -dumpstream mms://wm.nhk.or.jp/r1/asa/businesswm6/2b3.wma  -dumpfile tmp.wma

    mplayer -vo null -vc dummy -af resample=44100 -ao pcm:waveheader tmp.wma

    format1
    http://www.nhk.or.jp/r1/asa/tokiwadai.html

    format2
    http://www.nhk.or.jp/r1/asa/osusume.html
    http://www.nhk.or.jp/r1/asa/book.html
    http://www.nhk.or.jp/r1/asa/column/index.html
    http://www.nhk.or.jp/r1/asa/shinbun.html  (shin bun wo yonde)
    http://www.nhk.or.jp/r1/asa/culture.html

    # VLC failed log
    [0xa00e008] logger interface: using logger...
    [0xa0214a8] dummy interface: using the dummy interface module...
    [0xa028008] access_mms access: selecting stream[0x1] audio (31 kb/s)
    [0xa028008] access_mms access: connection successful
    [0xa02da90] demuxdump demux: dumping raw stream to file `mp3/100622-newsup.wma'
    [0xa02da90] demuxdump demux: closing mp3/100622-newsup.wma (1069 Kbytes dumped)
    [0xa028008] access_mms access error: failed to send command
    [0xa009020] main playlist: end of playlist, exiting

}

proc usage {} {
    puts "Usage:"
    puts "    tclsh [info script] ?options? -titles <section> ..."
    puts "    tclsh [info script] ?options? -auto   <section> ..."
    puts "Currently there are no options ..."
    puts "Sections that are working    : business book"
    puts "Sections that are not working: newsup column news"
}

proc hasopt {argv opt} {
    if {[llength $argv] == 0} {
        return 1
    } elseif {[lsearch -exact $argv $opt] >= 0} {
        return 1
    } else {
        return 0
    }
}

proc wget {url {encoding shiftjis}} {
    puts -nonewline "wget $url .."
    set result ""
    catch {
        set fd [open "|wget -q -O - $url 2> /dev/null"]
        fconfigure $fd -encoding $encoding
        set result [read $fd]
        close $fd
    }
    puts " [string length $result] chars"
    return $result
}

proc year {} {
    return [clock format [clock seconds] -format %Y]
}

proc shortdate {date} {
    regsub ^20 $date ""  date
    return $date
}

proc titles_xml {home suffix album category} {
    set titles {}
    set data [wget $home utf-8]

    regsub -all "<enclosure url=" $data "\uFFFF" data
    foreach part [split $data \uFFFF] {
        if {[regexp {^"([^\"]+[.]mp3)"} $part dummy url] && 
            [regexp {<title>([0-9]+)年([0-9]+)月([0-9]+)日} $part dummy yy mm dd] &&
            [regexp {<description>([^<]+)} $part dummy title]} {

            if {[string length $mm] < 2} {
                set mm 0$mm
            }
            if {[string length $dd] < 2} {
                set dd 0$dd
            }

            set artist "00 - NHK"
            set date [shortdate $yy$mm$dd]
            set file "$date-$suffix.mp3"
            set title "$date - $category - [string trim $title]"
            lappend titles [list $url $file $artist $album $title]
        }
    }

    return $titles
}


proc titles_format1 {home suffix album category} {
    set titles {}
    set data [wget $home]

    regsub -all {<font[^>]*>} $data "" data
    regsub -all {</font[^>]*>} $data "" data
    regsub -all {<span[^>]*>} $data "" data
    regsub -all {</span[^>]*>} $data "" data
    regsub -all {<br>} $data "" data
    regsub -all {(([0-9]+)月([0-9]+)日)} $data "\uFFFF\\1" data

    foreach part [split $data \uFFFF] {
        if {[regexp {<a href="([^\"]+[.]asx)">} $part dummy asx] &&
            [regexp {>([^<]+)<a href="([^\"]+[.]asx)">} $part dummy title] &&
            [regexp {([0-9]+)月([0-9]+)日} $part dummy month day]} {
            if {$month < 10} {
                set month 0$month
            }
            if {$day < 10} {
                set day 0$day
            }
            set date [shortdate [year]$month$day]
            set url http://www.nhk.or.jp/r1/asa/$asx
            set file "$date-$suffix.mp3"
            set artist "00 - NHK"
            regsub -all "\[ \t\n\r　\]+" $title " " title
            set title "$date - $category - [string trim $title]"
            lappend titles [list $url $file $artist $album $title]
        } else {
            #puts $part
        }
    }
    return $titles
}

proc titles_asa_business {} {
    return [titles_xml http://www.nhk.or.jp/r1/asa/podcast/business.xml business "NHK Asa" "ビジネス展望"]
    #return [titles_format1 http://www.nhk.or.jp/r1/asa/business.html business "NHK Asa" "ビジネス展望"]
}

proc titles_asa_newsup {} {
    return [titles_xml http://www.nhk.or.jp/r1/asa/podcast/newsup.xml newsup "NHK Asa" "NewsUp"]
}

proc titles_asa_book {} {
    return [titles_xml http://www.nhk.or.jp/r1/asa/podcast/book.xml book "NHK Asa" "Book"]
}

proc titles_asa_column {} {
    return [titles_xml http://www.nhk.or.jp/r1/asa/column/column.xml column "NHK Asa" "Column"]
}

proc titles_asa_tokiwadai {} {
    return [titles_format1 http://www.nhk.or.jp/r1/asa/tokiwadai.html tokiwadai "NHK Asa" "時の話題"]
}

proc titles_nhk_news {} {
    set titles {}

    foreach line [split [wget http://www.nhk.or.jp/r-news/] \n] {
        if {[regexp {"([^\"]+[.]asx)"} $line dummy asx]} {
            #puts $line
            if {[regexp {/(201[0-9]....)_1} $line dummy date]} {
                set url $asx
                puts $url
                if {[regexp noon $line]} {
                    set time "12:00"
                } elseif {[regexp morning $line]} {
                    set time "07:00"
                } elseif {[regexp 22news $line]} {
                    set time "22:00"
                } elseif {[regexp midnight $line]} {
                    set time "23:50"
                } else {
                    set time "19:00"
                }
                set date [shortdate $date]
                set title "$date - News $time"
                regsub : $time "" time
                set file "$date-news-$time.mp3"
                set artist "00 - NHK"
                set album  "NHKNews"
                lappend titles [list $url $file $artist $album $title]
            }
        }
    }

    return [lrange [lsort -decreasing $titles] 0 1]
}

rename exec exec.orig
proc exec {args} {
    puts "exec $args"
    return [eval exec.orig $args]
}

proc setid3 {mp3 artist album title} {
    exec id3v2 -D $mp3 2>@ stderr >@ stdout
    exec eyeD3 --set-encoding=utf16-LE \
        -a $artist -A $album \
        -t "$title ." $mp3 2>@ stderr >@ stdout
}

proc titles {verbose argv} {
    set titles {}

    if {[hasopt $argv newsup]} {
        set titles [concat $titles [titles_asa_newsup]]
    }
    if {[hasopt $argv business]} {
        set titles [concat $titles [titles_asa_business]]
    }
    if {[hasopt $argv book]} {
        set titles [concat $titles [titles_asa_book]]
    }
    if {[hasopt $argv column]} {
        set titles [concat $titles [titles_asa_column]]
    }
    #if {[hasopt $argv tokiwadai]} {
    #    set titles [concat $titles [titles_asa_tokiwadai]]
    #}
    if {[hasopt $argv news]} {
        set titles [concat $titles [titles_nhk_news]]
    }

    if {$verbose} {
        foreach n $titles {
            puts "GOT: $n"
        }
    }

    return $titles
}

proc getasx {asx mp3} {
    set test 0
    set data [wget $asx]
    set tmp /tmp/getnhk-[pid].wma
    set wav /tmp/getnhk-[pid].wav

    foreach stalefile [glob -nocomplain /tmp/getnhk-*.wma] {
        puts "Need to remove $stalefile"
        catch {file delete $stalefile}
    }

    if {$test} {
        set tmp [file root $mp3].wma
    }

    if {[regexp {"(mms:[^\"]+[.]wma)"} $data dummy mms]} {
        puts "mms = $mms"
        puts "mp3 = $mp3"
        puts "tmp = $tmp"

        if {!$test} {
            file delete -force $tmp
        }

        if {![file exists $tmp]} {
            if 1 {
                catch {
                    exec tclsh watch.tcl $tmp 2>@ stderr >@ stdout &
                    exec cvlc $mms \
                        :mms-caching=100000000 :demux=dump :demuxdump-file=$tmp \
                        --play-and-exit  \
                        2>@ stderr >@ stdout
                }
            } else {
                catch {
                    exec mplayer -dumpstream $mms \
                        -dumpfile $tmp \
                        2>@ stderr >@ stdout
                }
            }
        }

        #catch {
        #        exec cvlc -q $tmp --sout \
        #            "#transcode{acodec=mp3}:duplicate{dst=std{access=file,mux=raw,dst=\"$mp3\"},select=\"novideo\"}" \
        #            --play-and-exit \
        #            2>@ stderr >@ stdout
        #}
        catch {
            exec nice mplayer -vo null -vc dummy -af resample=44100 -ao pcm:waveheader:file=$wav $tmp \
                2>@ stderr >@ stdout
        }
        catch {
            exec nice lame -b 64 -S -m m -f $wav -o $mp3 \
                2>@ stderr >@ stdout
        }

        if {!$test} {
            file delete -force $tmp
        }

        file delete -force $wav
    }
}


proc get {n} {
    set url [lindex $n 0]

    if {[regexp {[.]asx$} $url]} {
        get_mms $n
    } else {
        get_mp3 $n
    }
}

proc get_mms {n} {
    set url    [lindex $n 0]
    set mp3    [lindex $n 1]
    set artist [lindex $n 2]
    set album  [lindex $n 3]
    set title  [lindex $n 4]

    set file mp3/$mp3

    if {[file exists $file]} {
        puts "Already exists $file: $title"
        if 1 {
            return
        }
    } else {
        puts "============================================================"
        puts "Downloading $file <= $url "
        puts "$title"
        puts "============================================================"

        if 0 {
            set tmp mp3/zztmp.mp3
            file delete -force $tmp
            #file copy foo.mp3 $tmp

            exec cvlc -q $url --sout \
                "#transcode{acodec=mp3}:duplicate{dst=std{access=file,mux=raw,dst=\"$tmp\"},select=\"novideo\"}" \
                --play-and-exit \
                2>@ stderr >@ stdout

            setid3 $tmp $artist $album $title
            file delete -force $file
            file rename $tmp $file
        } else {
            getasx $url $file
        }
    }

    setid3 $file $artist $album $title
    sync
}

proc get_mp3 {n} {
    set url    [lindex $n 0]
    set mp3    [lindex $n 1]
    set artist [lindex $n 2]
    set album  [lindex $n 3]
    set title  [lindex $n 4]

    set file mp3/$mp3

    if {[file exists $file]} {
        puts "Already exists $file: $title"
        if 0 {
            setid3 $file $artist $album $title
        }

        return
    } else {
        puts "============================================================"
        puts "Downloading $file <= $url "
        puts "$title"
        puts "============================================================"

        set tmp $file.tmp
        file delete -force $tmp
        exec wget -O $tmp $url \
                2>@ stderr >@ stdout

        setid3 $tmp $artist $album $title
        file delete -force $file
        file rename $tmp $file
    }
}

proc getall {argv} {
    foreach n [lsort -decreasing [titles 0 $argv]] {
        get $n
    }
}

proc sync {} {
    set files [glob mp3/*.mp3]
    set news {}
    set pod  {}

    # want to save pod casts for longer but news for shorter.
    # also news is larger so want to conserve space on server
    foreach f $files {
        if {[regexp {[-]news[-]} $f]} {
            lappend news $f
        } else {
            lappend pod $f
        }
    }

    dosync html/pod/nhknews  3 $news
    dosync html/pod/nhkpod  10 $pod
}

proc dosync {dir max files} {
    set script [file dir [info script]]/../tools/sync.tcl
    eval exec tclsh $script $dir $max $files 2>@ stderr >@ stdout
}

proc main {argv} {
    if {[lindex $argv 0] == "-titles"} {
        titles 1 [lrange $argv 1 end]
    } elseif {[lindex $argv 0] == "-auto"} {
        while 1 {
            puts [exec date]
            getall [lrange $argv 1 end]
            sync
            puts [exec date]
            puts "Sleeping now"
            exec sleep 3600
        }
    } else {
        usage
    }
}

main $argv
