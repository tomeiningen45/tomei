#----------------------------------------------------------------------
# Shared scripts [to be moved to separate file]
#----------------------------------------------------------------------

proc wget {url {encoding utf-8}} {
    global env

    set started [now]
    if {[info exists env(RSSVERBOSE)]} {
        puts -nonewline "wget $url"
	flush stdout
    }
    set data ""
    set tmpfile /tmp/wget-rss-[pid]
    set comp_msg ""
    if {[catch {
        exec wget --timeout=10 --tries=1 -q -O $tmpfile $url 2> /dev/null > /dev/null
        set type [exec file $tmpfile]
        if {[regexp compressed $type]} {
            set cmd "|cat $tmpfile | zcat"
            set comp_msg " (gzip)"
        } else {
            set cmd "|cat $tmpfile"
        }
        if {[info exists env(USEICONV)] && "$encoding" == "gb2312"} {
            set fd [open "$cmd | iconv -f gbk -t utf-8" r]
            set encoding utf-8 
        } else {
            set fd [open "$cmd" r]
        }
        fconfigure $fd -encoding $encoding
        set data [read $fd]
    } err]} {
        puts $err
    }

    catch {
        close $fd
    }

    if {[info exists env(RSSVERBOSE)]} {
        puts " [expr [now] - $started] secs/ [string length $data] words$comp_msg"
    }

    catch {
        file delete -force $tmpfile
    }
    return $data
}

proc makelist {data splitter} {
    regsub -all $splitter $data \uFFFF data
    set list [split $data \uFFFF]
    return [lrange $list 1 end]
}

proc getcachefile {localname} {
    global datadir

    return $datadir/[file tail $localname]
}

proc getfile {link localname {encoding utf-8}} {
    global env
    set fname [getcachefile $localname]

    set x $encoding
    if {[info exists env(USEICONV)] && "$encoding" == "gb2312"} {
        set encoding utf-8
    }

    if {![file exists $fname]} {
        set data [wget $link $x]
        set fd [open $fname w+]
        fconfigure $fd -encoding $encoding
        puts -nonewline $fd $data
        close $fd
    } else {
        set fd [open $fname]
        fconfigure $fd -encoding $encoding
        set data [read $fd]
        close $fd
    }
    return $data
}

proc makeitem {title link data date} {
    catch {
        # if passed in an integer, make it into a date string
        set date [clock format $date]
    }

    set t "\n\
	<item>\n\
	<title><!\[CDATA\[$title\]\]></title>\n\
	<link>$link</link>\n\
	<description><!\[CDATA\[$data\]\]></description>\n\
	<pubDate>$date</pubDate>\n\
	</item>"

    return $t
}

proc now {} {
    return [clock seconds]
}


# Return a list of {title link description pubdate ...} from an RSS feed
# Works for cnbeta: http://cnbeta.com/backend.php
proc extract_feed {url} {
    set data [wget $url]
    set list ""
    if {[regexp {<feed xmlns="http://www.w3.org/2005/Atom"} $data]} {
        foreach part [makelist $data <entry] {
            if {![regexp {<link [^>]*href="([^>]+)"[^>]*/>} $part dummy link]} {
                continue
            }
            if {![regexp {<title [^>]*>([^<]+)</title>} $part dummy title]} {
                continue
            }
            if {![regexp {<summary [^>]*>([^<]+)</summary>} $part dummy description]} {
                continue
            }
            if {![regexp {<updated>([^<]+)</updated>} $part dummy pubdate]} {
                continue
            }
            lappend list $title $link $description $pubdate
        }
        return $list
    }

    foreach part [makelist $data <item] {
        if {![regexp {<title>(.*)</title>} $part dummy title]} {
            continue
        }
        if {![regexp {<link>(.*)</link>} $part dummy link]} {
            continue
        }

        if {![regexp {<description>(.*)</description>} $part dummy description]} {
            continue
        }
        if {![regexp -nocase {<pubdate>(.*)</pubdate>} $part dummy pubdate] &&
            ![regexp -nocase {<dc:date>(.*)</dc:date>} $part dummy pubdate]} {
            continue
        }

        lappend list $title $link $description $pubdate
    }

    return $list
}

proc save_links {datadir newlinks {limit 200}} {
    set file $datadir.links

    if {[file exists $file]} {
        set fd [open $file]
        while {![eof $fd]} {
            set line [string trim [gets $fd]]
            if {"$line" != ""} {
                set date [lindex $line 0]
                set link [lindex $line 1]
                set table($date) $link
            }
        }
        close $fd
    }

    foreach {date link} $newlinks {
        set table($date) $link
    }

    set links {}
    set n 0
    set fd [open $file w+]
    foreach date [lsort -integer -decreasing [array names table]] {
        set link $table($date)
        puts $fd [list $date $link]
        incr n
        if {$n >= $limit} {
            break;
        }
        lappend links $link
    }
    close $fd

    return $links
    #parray table
}

proc read_links {datadir} {
    set file $datadir.links

    set list {}

    if {[file exists $file]} {
        set fd [open $file]
        while {![eof $fd]} {
            set line [string trim [gets $fd]]
            if {"$line" != ""} {
                set link [lindex $line 1]
                lappend list $link
            }
        }
        close $fd
    }

    return $list
}

proc ssh_prog {} {
    global env
    if {[info exists env(RSS_SSH)]} {
        return $env(RSS_SSH)
    }
    return ssh
}

proc scp_prog {} {
    global env
    if {[info exists env(RSS_SCP)]} {
        return $env(RSS_SCP)
    }
    return scp
}

proc compare_integer {a b} {
    if {$a > $b} {
        return 1
    } elseif {$a == $b} {
        return 0
    } else {
        return -1
    }
}

proc compare_file_date {a b} {
    return [compare_integer [file mtime $a]  [file mtime $b]]
}

if {[info command lreverse] == ""} {
    proc lreverse {list} {
	set length [llength $list]
	set result ""
	for {set n [expr $length - 1]} {$n >= 0} {incr n -1} {
	    lappend result [lindex $list $n]
	}
	return $result
    }
}

proc testing_get_file {data {encoding utf-8}} {
    global env test_data

    if {[info exists env(RSS_TEST_URL)]} {
        if {![info exists test_data]} {
            set test_data [wget $env(RSS_TEST_URL) $encoding]
        }
        set data $test_data
    }
    return $data
}

proc foreach_json {data cmd} {
    foreach {tag value} $data {
        uplevel set tag [list $tag]
        uplevel set value [list $value]
        uplevel $cmd
    }
}

proc split_json {data arrname} {
    catch {
        uplevel unset [$list $arrname]
    }
    foreach {tag value} $data {
        uplevel set [set arrname]([list $tag]) [list $value]
    }
}

# subsritute block(s) between two regexps
proc sub_block {data begin end rep} {
    regsub -all $begin $data \uFFFE data
    regsub -all $end   $data \uFFFF data
    regsub -all {\uFFFE[^\uFFFF]*\uFFFF} $data $rep data
    return $data
}

proc lowcap {line} {
    set prefix ""
    set val ""
    foreach word [split $line " "] {
        if {[regexp {^([A-Z])([A-Za-z].*)$} $word dummy first rest]} {
            set word ${first}[string tolower $rest]
        }
        append val ${prefix}${word}
        set prefix " "
    }
    return $val
}

#-------------------------------------------------------------------------------
# new gen scripting follows ...
#-------------------------------------------------------------------------------

proc do_multi_sites {sites {argv {}}} {
    foreach s $sites {
        if {$argv != {} && [lsearch $s $argv] < 0} {
            continue
        }
        do_one_site $s
    }
}

proc do_one_site {siteinfo} {
    global datadir env

    set sitename   [lindex $siteinfo 0]
    set mainurl    [lindex $siteinfo 1]
    set index_proc [lindex $siteinfo 2]
    set body_proc  [lindex $siteinfo 3]

    set datadir data/$sitename
    catch {file mkdir $datadir}

    if {$index_proc == {}} {
        set index_proc ${sitename}_index_proc
    }
    if {$body_proc == {}} {
        set body_proc ${sitename}_body_proc
    }

    set lang en
    set date [clock format [clock seconds]]

    set out "<?xml version=\"1.0\" encoding=\"utf-8\"?> \n\
        <rss xmlns:dc=\"http://purl.org/dc/elements/1.1/\" \n\
             xmlns:sy=\"http://purl.org/rss/1.0/modules/syndication/\" \n\
             xmlns:admin=\"http://webns.net/mvcb/\" \n\
             xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" \n\
             xmlns:georss=\"http://www.georss.org/georss\" version=\"2.0\"> \n\
       <channel> \n\
         <title>$sitename</title> \n\
         <link>$mainurl</link> \n\
         <description>$sitename</description> \n\
         <dc:language>$lang</dc:language> \n\
         <pubDate>$date</pubDate> \n\
         <dc:date>$date</dc:date> \n\
         <sy:updatePeriod>hourly</sy:updatePeriod> \n\
         <sy:updateFrequency>1</sy:updateFrequency> \n\
         <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>"

    set max 50
    catch {
        set max $env(MAX_${sitename})
    }

    set n 0
    set lastdate 0xffffffff

    foreach item [$index_proc $mainurl] {
        incr n
        if {$n > $max} {
            break
        }
        set url    [lindex $item 0]
        set title  [lindex $item 1]
        set fname  [lindex $item 2]

        if {[info exists env(DEBUG_TIT_ONLY)]} {
            puts $url=$title
            continue
        }
        if {"$fname" == ""} {
            set fname [getcachefile $url]
        }

        set data [getfile $url $fname]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        set data [$body_proc $data]

        puts $url=$title=$date
        append out [makeitem $title $url $data $date]
    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

proc standard_index_proc {url match {pretrim {}} {posttrim {}}} {
    set data [wget $url]
    if {"$pretrim" != ""} {
        regsub $pretrim $data "" data
    }
    if {"$posttrim" != ""} {
        regsub $posttrim $data "" data
    }

    standard_index_proc_0 $data $match
}

proc standard_index_proc_0 {data match} {
    #puts $data
    set pat    [lindex $match 0]
    set urlidx [lindex $match 1]
    set titidx [lindex $match 2]

    set results {}
    #puts $pat
    while {[regexp $pat $data dummy a b c d e]} {
        #puts $a
        regsub $pat $data "" data
        set list [list $a $b $c $d $e]
        set url [lindex $list $urlidx]
        set tit [lindex $list $titidx]
        lappend results [list $url $tit]
    }

    return $results
}

proc filter_out {list script} {
    set results {}

    foreach item $list {
        set url   [lindex $item 0]
        set title [lindex $item 1]
        catch {eval $script} code
        if {!$code} {
            lappend results $item
        } else {
            #puts hello
        }
    }

    return $results
}

proc process_indices {list script} {
    set results {}

    foreach item $list {
        set url   [lindex $item 0]
        set title [lindex $item 1]
        catch {eval $script} code
        lappend results [list $url $title]
    }

    return $results
}

proc extract_and_junk_one_block {dataName begin end} {
    upvar $dataName data

    regsub -all $begin $data \uFFFE data
    regsub -all $end   $data \uFFFF data
    set pat {\uFFFE([^\uFFFF]*)\uFFFF}

    set result {}
    if {[regexp $pat $data dummy result]} {
        regsub $pat $data "" data
    }

    regsub -all \uFFFE $data $begin data
    regsub -all \uFFFF $data $end   data

    return $result
}

