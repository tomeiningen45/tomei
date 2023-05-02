# This script should not be run by itself. It should always be launched via rss-nt.sh
#
# This is the main loop of rss-nt, which
# (1) discovers adapters for new web sites (by grepping '# @rss-nt-adapter@'
#     in all the tcl scripts in the current directory,
# (2) schdules all the adapters to run at regular intervals (TBD configurable)

#package require ncgi

source [file dirname [info script]]/rss-lib.tcl
set env(CLASSPATH) [file dirname [info script]]

#======================================================================
# SECTION: global configuration
#======================================================================
proc init_globals {} {
    global g
    set g(rootdir) [file dirname [info script]]

    if 0 {
        # scan for adapters every 20 seconds
        set g(t:discover) 20000
    } else {
        # scan for adapters every 120 seconds
        set g(t:discover) 120000
    }

    # Max number of concurrent downloads
    set g(maxwget) 60
    set g(maxwget) 4
    #set g(maxwget) 1

    # Max number of concurrent downloads
    set g(maxwgetpersite) 10

    set g(wgets) 0
    set g(wget_later) {}

    set g(has_unsaved_articles) 0

    set g(max_articles)  [get_debug_opt DEBUG_MAX_ARTICLES  280]
    set g(max_downloads) [get_debug_opt DEBUG_MAX_DOWNLOADS 280]
}

#======================================================================
# SECTION: global debug functions
#======================================================================

proc xcatch {script} {
    global env

    if {[catch {
        uplevel eval $script
    } err]} {
        if {[info exists env(DEBUG)]} {
            global errorInfo
            puts $err
            puts $errorInfo
        }
    }
}

proc xafter {t script} {
    global g
    after $t $script
    #after 1000 $script
}

proc xlog {level s} {
    puts $s
}

proc get_debug_opt {opt {default ""}} {
    global env
    if {[info exists env($opt)]} {
	set data ""
	catch {
	    set data [string trim $env($opt)]
	}
        return $data
    } else {
        return $default
    }
}

proc test_html_file {} {
    return [file join [storage_root] test.html]
}

proc save_test_html {data {encoding utf-8}} {
    set fd [open [test_html_file] w+]

    set head {<html>
        <head>
        <META HTTP-EQUIV="content-type" CONTENT="text/html; charset=ENCODING"></head>}

    regsub ENCODING $head $encoding head

    puts $fd $head
    puts $fd $data
    close $fd
}

#======================================================================
# SECTION: global functions
#======================================================================

proc wget {url {encoding utf-8}} {
    global env

    if {[info exists env(WGET_INIT_WAIT)]} {
        set initwait $env(WGET_INIT_WAIT)
    } else {
        set initwait [list 0]
    }

    if {[info exists env(WGET_RETRY)]} {
        if {"$env(WGET_RETRY)" == "default"} {
            set env(WGET_RETRY) {100 400 1000 2000 4000}
        }
        set initwait [concat $initwait $env(WGET_RETRY)]
    }

    if {[info exists env(WGET_NOWAIT)]} {
        set initwait 0
    }

    foreach time $initwait {
        after $time
        set data [wget_inner $url $encoding]
        if {[string length $data] > 0} {
            return $data
        }
        puts "--- RETRY --- $url"
    }

    return ""
}

proc wget_inner {url {encoding utf-8}} {
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
        exec wget --no-check-certificate --timeout=10 --tries=1 -q -O $tmpfile $url 2> /dev/null > /dev/null
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
        } elseif {"$encoding" == "utf-8"} {
            # Tcl cannot handle some UTF8 characters :-(
            set fd [open "$cmd | java FilterEmoji" r]
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

proc makelist {data splitter {startidx 1}} {
    regsub -all $splitter $data \uFFFF data
    set list [split $data \uFFFF]
    return [lrange $list $startidx end]
}

proc getcachefile {localname} {
    global datadir

    return $datadir/[file tail $localname]
}

proc getfile {link localname {encoding utf-8} {isnew_ret {}} {extralinks {}}} {
    global env
    set fname [getcachefile $localname]

    if {$isnew_ret != {}} {
        upvar $isnew_ret isnew
    }

    set x $encoding
    if {[info exists env(USEICONV)] && "$encoding" == "gb2312"} {
        set encoding utf-8
    }

    if {![file exists $fname] || [file size $fname] == 0} {
        set data [wget $link $x]
        set fd [open $fname w+]
        fconfigure $fd -encoding $encoding
        puts -nonewline $fd $data
        foreach elink $extralinks {
            set d [wget $elink $x]
            puts -nonewline $fd $d
            append data $d
        }
        close $fd
        set isnew 1
    } else {
        set fd [open $fname]
        fconfigure $fd -encoding $encoding
        set data [read $fd]
        close $fd
        set isnew 0
    }
    return $data
}

proc makeitem {title link data date} {
    catch {
        # if passed in an integer, make it into a date string
        set date [clock_format $date]
    }

    #if {[regexp "&" $link] && ![regexp "&amp;" $link]} {
    #    regsub -all & $link "&amp;" link
    #}

    set t "\n\
	<item>\n\
	<title><!\[CDATA\[$title\]\]></title>\n\
	<link><!\[CDATA\[$link\]\]></link>\n\
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
#
# Hmmm, seems like atom_update_index is better. Why do we have two variants?
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
    fconfigure $fd -encoding utf-8
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

# substitute block(s) between two regexps
proc sub_block {data begin end rep} {
    regsub -all $begin $data \uFFFE data
    regsub -all $end   $data \uFFFF data
    regsub -all {\uFFFE[^\uFFFF]*\uFFFF} $data $rep data
    return $data
}

proc sub_block_single {data begin end rep} {
    regsub $begin $data \uFFFE data
    regsub $end   $data \uFFFF data
    regsub {\uFFFE[^\uFFFF]*\uFFFF} $data $rep data
    return $data
}

proc sub_block_single_cmd {data begin end cmd} {
    set olddata $data
    regsub $begin $data \uFFFE data
    regsub $end   $data \uFFFF data
    set pat {\uFFFE([^\uFFFF]*)\uFFFF}
    if {[regexp $pat $data dummy found]} {
        regsub $pat $data [$cmd $found] data
        return $data
    } else {
        return $olddata
    }
}

proc noscript {data} {
    return [sub_block $data "<script" "</script>" ""]
}

proc nostyle {data} {
    return [sub_block $data "<style" "</style>" ""]
}

proc nosvg {data} {
    return [sub_block $data "<svg" "</svg>" ""]
}

proc notag_only {data tag {rep1 {}} {rep2 {}}} {
    regsub -nocase -all  "<$tag\[^\>]*>" $data "$rep1" data
    regsub -nocase -all "</$tag\[^\>]*>" $data "$rep2" data
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
    set date [clock_format [clock seconds]]

    regsub -all & $mainurl "&amp;" mainurl_s

    set out "<?xml version=\"1.0\" encoding=\"utf-8\"?> \n\
        <rss xmlns:dc=\"http://purl.org/dc/elements/1.1/\" \n\
             xmlns:sy=\"http://purl.org/rss/1.0/modules/syndication/\" \n\
             xmlns:admin=\"http://webns.net/mvcb/\" \n\
             xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" \n\
             xmlns:georss=\"http://www.georss.org/georss\" version=\"2.0\"> \n\
       <channel> \n\
         <title>$sitename</title> \n\
         <link>$mainurl_s</link> \n\
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
        set body   [lindex $item 3]
        set date   [lindex $item 4]

        if {[info exists env(DEBUG_TIT_ONLY)]} {
            puts $url=$title
            continue
        }
        if {"$fname" == ""} {
            set fname [getcachefile $url]
        }

        if {"$body" != ""} {
            if {"$date" == ""} {
                set date [clock seconds]
            }
            set data $body
        } else {
            set data [getfile $url $fname]
            set date [file mtime $fname]
            if {$date >= $lastdate} {
                set date [expr $lastdate - 1]
            }
            set lastdate $date
            set data [$body_proc $data]
        }

        puts "[clock_format $date] $url=$title"
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

proc quoted_exp {} {
    return "\[^\"\]"
}


proc generic_news_site {list_proc parse_proc {max 50} {maxnew 1000000}} {
    global datadir env site

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">
  <channel>
    <title>DESC</title>
    <link>URL</link>
    <description>DESC</description>
    <dc:language>LANG</dc:language>
    <pubDate>DATE</pubDate>
    <sy:updatePeriod>hourly</sy:updatePeriod>
    <sy:updateFrequency>1</sy:updateFrequency>
    <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>
    }

    set date [clock_format [clock seconds]]
    regsub -all DATE        $out $date out
    regsub -all LANG        $out site(lang)  out
    regsub -all DESC        $out $site(desc) out
    regsub -all URL         $out $site(url)  out

    #set max 50
    catch {
        set max $env(MAXRSS)
    }
    catch {
        set maxnew $env(MAXRSSNEW)
    }
    set n 0
    set lastdate 0xffffffff

    set list [lrange [$list_proc] 0 $max]

    set gotnew 0
    set body {}
    foreach article [lreverse $list] {
        set link  [lindex $article 0]
        set id    [lindex $article 1]
        set extra [lindex $article 2]

        set fname [getcachefile $id]

        set isnew 0
        set data [getfile $link [file tail $fname] $site(encoding) isnew $extra]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        set item [$parse_proc $data]
        set title [lindex $item 0]
        set data  [lindex $item 1]
        set extra [lindex $item 2]
        set delete_if_old [lindex $item 3]

        puts $isnew/$gotnew=$link=$id=$title
        if {"$delete_if_old" != "" && ([now] - [file mtime $fname] > $delete_if_old)} {
            puts "too old $fname"
            catch {file delete $fname}
        }

        if {"$title" != "*abort*"} {
            set data "<div lang=\"$site(lang)\" xml:lang=\"$site(lang)\">$data</div>"
            set newitem [makeitem $title "<!\[CDATA\[$link$extra\]\]>" $data $date]
            set body "$newitem$body"
        }

        if {$isnew} {
            incr gotnew
            if {$gotnew >= $maxnew} {
                puts "Got new $gotnew article exceeded max $maxnew"
                break
            }
        }
    }

    append out $body
    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

#======================================================================
# SECTION: main control unit
#======================================================================
proc main {} {
    init_globals
    # restart every 1 hour(s) to avoid accumulating too much log or Tcl memory
    after [expr 1000 * 3600 * 1] do_exit
    discover
    vwait forever
}

proc discover {} {
    global g env

    set g(adapters) {}

    foreach file [lsort [glob $g(rootdir)/*.tcl]] {
        xcatch {
            set fd [open $file]
            set data [read $fd]
            foreach line [split $data \n] {
                if {[regexp {^# @rss-nt-adapter@} $line]} {
                    set adapter [file root [file tail $file]]
                    lappend g(adapters) $adapter

                    set first 0
                    if {![info exists g(mtime:$adapter)]} {
                        set g(mtime:$adapter) 0
                        set first 1
                    }
                    set mtime [file mtime $file]
                    if {$g(mtime:$adapter) < $mtime} {
                        set $g(mtime:$adapter) $mtime
                        xlog 1 "updating $file"
                        uplevel #0 source $file
                        adapter_init $adapter $first
                    }
                    break
                } elseif {[regexp {^# @rss-nt-lib@} $line]} {
                    xlog 1 "loading library $file"
                    uplevel #0 source $file
                }
            }
        }
        xcatch {
            close $fd
        }
    }

    if {[set d [get_debug_opt DEBUG_ADAPTERS]] != ""} {
        # for debug only
        set g(adapters) $d
    }

    if {[get_debug_opt DEBUG_ARTICLE] != ""} {
        set url [get_debug_opt DEBUG_ARTICLE]
        #set data [wget $url]
        #set fd [open orig.html w+]
        #puts $fd $data
        #close $fd
        [get_debug_opt DEBUG_ADAPTERS]::debug_article_parser $url
    } else {
        # regular mode -- update every adapter
        foreach adapter [random_sort $g(adapters)] {
            adapter_schedule_scan $adapter
        }
    }

    xafter $g(t:discover) discover

    #schedule_idle_handler
}


proc random_sort {list} {
    set n {}
    foreach i $list {
	lappend n [list [format %9x [expr int(rand() * 0xf0000000)]] $i]
    }
    set o {}
    foreach pair [lsort $n] {
	lappend o [lindex $pair 1]
    }
    return $o
}

proc schedule_idle_handler {} {
    global g
    if {![info exists g(idle_handler)]} {
        set g(idle_handler) [after idle do_idle_handler]
        xlog 1 "scheduled idle handler $g(idle_handler)"
    }
}

proc do_idle_handler {} {
    global g
    unset g(idle_handler)
    xlog 1 "idle handler running"
    xcatch {db_sync_all_to_disk}
}

proc adapter_init {adapter first} {
    global g

    # Default confguration of an adapter
    namespace eval $adapter {
        variable h

        set h(datadir) $g(rootdir)/data/6park
        xcatch {
            file mkdir $h(datadir)
        }

        if {![info exists h(last_indexed_time)]} {
            set h(last_indexed_time) 0
        }

        # Make it easy to say "global g h" to access g (the global config) and h
        # (the local config for this particular adapter).
        proc global {args} {
            foreach v $args {
                if {[info exists ::$v]} {
                    uplevel namespace upvar :: $v $v
                } else {
                    uplevel variable $v
                }
            }
        }

        # index update frequency - update every 5 minutes
        set h(freq:index) [expr 5 * 60 * 1000]

        # article delay - download the article 0 minute after it's first indexed
        # (a longer delay allows some (popular) comments to be included in the RSS feed
        set h(delay:article) [expr 0 * 60 * 1000]

        set h(article_sort_byurl) 0
        set h(filter_duplicates)  0
        set h(max_articles) 100
    }
    set ${adapter}::h(out) $adapter
    db_load $adapter

    # Adapter-specific config initialization
    namespace eval $adapter "init $first"

}

proc adapter_schedule_scan {adapter} {
    puts "Scanning $adapter"
    namespace eval $adapter {
        variable h
        set now [::now]
        if {$now - $h(last_indexed_time) >= $h(freq:index)} {
            # Need to scan again
	    set h(indices) {}
            update_index
        }
    }
}

# TODO: if too many reads, queue them (in case select fails ...)
proc schedule_read {doer url {encoding utf-8}} {
    global buff g

    xlog 1 "schedule_read $url"

    #set data [wget http://news.6park.com/newspark/index.php gb2312]

    if {$g(wgets) < $g(maxwget)} {
        if {![info exists g(no_more_download)]} {
            incr g(wgets)
            do_wget_now $doer $url $encoding
        }
    } else {
        do_wget_later $doer $url $encoding
    }
}

proc do_wget_now {doer url encoding} {
    global buff g

    xlog 2 "wget $doer $url $encoding"

    set cmd "| wget --compression=auto --no-check-certificate --timeout=10 --tries=1 -q -O - -o /dev/null $url"
    if {"$encoding" == "utf-8"} {
        # Tcl cannot handle some UTF8 characters :-(
        append cmd " | java FilterEmoji"
    }
    if {"$encoding" == "gb2312"} {
        append cmd " | iconv -f gbk -t utf-8"
        set encoding utf-8
    }

    set fd [open $cmd]
    set buff($fd,url)  $url
    set buff($fd,doer) $doer
    set buff($fd,data) ""

    fconfigure $fd -encoding $encoding -blocking false
    fileevent $fd readable [list ::do_read $fd]
}

proc do_wget_later {doer url encoding} {
    global g

    lappend g(wget_later) [list $doer $url $encoding]
}

proc do_read {fd} {
    global buff g

    if {![eof $fd]} {
        append buff($fd,data) [read $fd]
    } else {
        set doer $buff($fd,doer)
        set data $buff($fd,data)
        set url $buff($fd,url)

        unset buff($fd,data)
        unset buff($fd,doer)
        close $fd

        if {[get_debug_opt DEBUG_ARTICLE] != ""} {
            puts ======================================================================
            puts "writing orig.html"
            puts ======================================================================

            set fd [open orig.html w+]
            puts $fd "$data"
            close $fd
        }

        eval $doer [list $url] [list $data]

        puts [llength $g(wget_later)]=$g(wgets)
        if {[llength $g(wget_later)] > 0} {
	    set g(wget_later) [random_sort $g(wget_later)]
            set next [lindex $g(wget_later) 0]
            set g(wget_later) [lrange $g(wget_later) 1 end]

            if {[info exists g(no_more_download)]} {
                incr g(wgets) -1
            } else {
                do_wget_now [lindex $next 0] [lindex $next 1] [lindex $next 2]
            }
        } else {
            incr g(wgets) -1
        }

        if {$g(wgets) == 0} {
            xcatch {db_sync_all_to_disk}
        }
    }
}

proc atom_update_index {adapter index_url {encoding utf-8}} {
    schedule_read [list atom_parse_index $adapter $encoding] $index_url
}

proc atom_parse_index {adapter encoding index_url data} {
    lappend ${adapter}::h(indices) $index_url 
    
    set list {}
    foreach line [makelist $data <item>] {
        if {[regexp {<link>([^<]+)</link>} $line dummy link] &&
            [regexp {<pubDate>([^<]+)</pubDate>} $line dummy pubdate]} {

            if {[catch {
                # Tcl cannot parse "Sun, 27 Dec 2020 23:02:21 +0900"
                regsub {[+-][0-9]+$} $pubdate "" pubdate
                set pubdate [clock scan $pubdate]
            } err]} {
                puts $err
                continue
            }

            regsub -all {&#45;} $link - link

            maybe_append_link list $adapter $pubdate $link
        }
    }

    if {[llength $list] == 0 && [regexp {<feed xmlns="http://www.w3.org/2005/Atom"} $data]} {
        foreach part [makelist $data <entry] {
            if {![regexp {<link [^>]*href="([^>]+)"[^>]*/>} $part dummy link]} {
                continue
            }
            if {![regexp {<updated>([^<]+)</updated>} $part dummy pubdate]} {
                continue
            }

            if {[catch {
                # Tcl cannot parse "Sun, 27 Dec 2020 23:02:21 +0900"
                regsub {[+-][0-9]+$} $pubdate "" pubdate
                set pubdate [clock scan $pubdate]
            } err]} {
                set pubdate [clock seconds]
            }

            regsub -all {&#45;} $link - link

	    # FIXME -- use maybe_append_link
            lappend list [list [format 0x%016x $pubdate] [${adapter}::parse_link $link]]
        }
    }

    xlog 1 "$adapter found [llength $list] from source $index_url"

    # wget the oldest to newest
    foreach item [lsort $list] {
        # Get the oldest article first
        set pubdate     [lindex $item 0]
        set article_url [lindex $item 1]

        if {![db_exists $adapter $article_url]} {
            ::schedule_read [list ${adapter}::parse_article [expr $pubdate + 0]] $article_url $encoding
            incr n
            if {$n > 10} {
                # dont access the web site too heavily
                break
            }
        }
    }
}

proc rdf_update_index {adapter index_url {encoding utf-8}} {
    schedule_read [list rdf_parse_index $adapter $encoding] $index_url
}

proc maybe_append_link {list_var adapter pubdate link} {
    upvar $list_var list
    set item [${adapter}::parse_link $link]
    if {"$item" != ""} {
	lappend list [list [format 0x%016x $pubdate] $item]
    }
}

proc rdf_parse_index {adapter encoding index_url data} {
    lappend ${adapter}::h(indices) $index_url 
    
    set list {}
    foreach line [makelist $data "<item rdf:about="] {
        if {[regexp {^\"([^\"]+)\"} $line dummy link] &&
            [regexp {<dc:date>([^<]+)</dc:date>} $line dummy pubdate]} {

            if {[catch {
                # Tcl cannot parse "Sun, 27 Dec 2020 23:02:21 +0900"
                # or 2021-12-28T14:29:27+09:00
                regsub {[+-][0-9:]+$} $pubdate "" pubdate
                set pubdate [clock scan $pubdate]
            } err]} {
                puts $err
                continue
            }

            regsub -all {&#45;} $link - link

            lappend list [list [format 0x%016x $pubdate] [${adapter}::parse_link $link]]
        }
    }

    # wget the oldest to newest
    foreach item [lsort $list] {
        # Get the oldest article first
        set pubdate     [lindex $item 0]
        set article_url [lindex $item 1]

        if {![db_exists $adapter $article_url]} {
            ::schedule_read [list ${adapter}::parse_article [expr $pubdate + 0]] $article_url $encoding
            incr n
            if {$n > 10} {
                # dont access the web site too heavily
                break
            }
        }
    }
}

proc db_exists {adapter url} {
    return [info exists ${adapter}::dbs($url)]
}

proc save_article {adapter title url data {pubdate {}} {subpage {}}} {
    global g

    if {[get_debug_opt DEBUG_ARTICLE] != ""} {
        puts ======================================================================
        puts $url
        puts ======================================================================
        puts $title
        puts ======================================================================
        #puts $data

        set fd [open out.html w+]
        puts $fd "<title>$title</title>\n"
        puts $fd "<a href=$url>$url</a><p><p>\n"
        puts $fd "<h1>TITLE: $title</h1>"
        puts $fd "item data follows<hr>"
        puts $fd "$data"
        close $fd
        exit
    }

    if {$pubdate == {}} {
        set pubdate [clock seconds]
    }

    set filtered 0
    if {[info exists ${adapter}::h(unique_subject)] &&
        [info exists ${adapter}::seen_subject($title)]} {
        #puts "Filtered $url = $title"
        set filtered 1
    }

    set ${adapter}::seen_subject($title) 1

    # dbs = db for subject
    # dbt = db for time posted
    # dbc = db for content
    # dbf = db for filtered
    set ${adapter}::dbs($url) $title
    set ${adapter}::dbt($url) $pubdate
    set ${adapter}::dbc($url) $data
    set ${adapter}::dbf($url) $filtered
    if {$subpage != {}} {
        set ${adapter}::dbsp($url) $subpage
    }

    incr g(has_unsaved_articles) 1
    if {$g(has_unsaved_articles) >= $g(max_downloads)} {
        set g(no_more_download) 1
    }
}

proc filter_article {adapter url} {
    set ${adapter}::dbf($url) 1
}

proc adapter_db_file {adapter} {
    return [file join [storage_root] $adapter $adapter.db.tcl]
}

proc adapter_xml_file {adapter subpage} {
    set out [set ${adapter}::h(out)]
    if {$subpage != {}} {
        append out _${subpage}
    }
    return [file join [storage_root] $out.xml]
}

proc db_load {adapter} {
    xcatch {
        set db [adapter_db_file $adapter]
        if {[file exists $db]} {
            namespace eval $adapter source [list $db]

            foreach url [array names ${adapter}::dbs] {
                set title [set ${adapter}::dbs($url)]
                set ${adapter}::seen_subject($title) 1
            }
            #parray ${adapter}::seen_subject
        }
    }
}

proc date_string {{seconds 0}} {
    if {$seconds == 0} {
	set seconds [clock seconds]
    }
    return [clock format $seconds -format {%Y%m%d %H:%M:%S}]
}

proc db_sync_all_to_disk {} {
    global g env

    if {$g(has_unsaved_articles) == 0} {
        xlog 1 "no updates ... no need to sync to disk [clock format [clock seconds] -timezone :US/Pacific]"
        if {[info exists env(DEBUG_NO_LOOPS)]} {
            puts "env(DEBUG_NO_LOOPS) exists ... exiting"
            exit
        }
        return
    }
    set g(has_unsaved_articles) 0
    foreach adapter $g(adapters) {
        set db [adapter_db_file $adapter]
        xlog 2 "syncing $adapter $db"
        file mkdir [file dirname $db]
        set fd  [open $db w+]
        set fd2 [open [file root $db].html w+]
        puts $fd "variable dbs"
        puts $fd "variable dbt"
        puts $fd "variable dbc"
        puts $fd "variable dbf"
        puts $fd "variable dbsp"

	puts $fd2 "Updated [date_string]<p>Sources:<ul>"
	foreach i [set ${adapter}::h(indices)] {
	    puts $fd2 "<li><a href='$i'>$i</a>"
	}
	puts $fd2 "</ul><p>Articles:<ul>"
        # write the newest to oldest
        if {[set ${adapter}::h(article_sort_byurl)]} {
            set list [lsort -decreasing [array names ${adapter}::dbs]]
        } else {
            set n {}
            foreach url [array names ${adapter}::dbs] {
                lappend n [list [format %016x [set ${adapter}::dbt($url)]] $url]
            }
            set list {}
            foreach item [lsort -decreasing $n] {
                #puts [lindex $item 0]
                lappend list [lindex $item 1]
            }
        }

        if {[set ${adapter}::h(filter_duplicates)]} {
            set list [${adapter}::filter_duplicates $list]
        }
        set n 0
        foreach url $list {
            #xlog 3 "... saving [set ${adapter}::dbs($url)] - $url"
            puts $fd "set ${adapter}::dbs($url) [list [set ${adapter}::dbs($url)]]"
            puts $fd "set ${adapter}::dbt($url) [list [set ${adapter}::dbt($url)]]"
            puts $fd "set ${adapter}::dbc($url) [list [set ${adapter}::dbc($url)]]"
            catch {
            puts $fd "set ${adapter}::dbf($url) [list [set ${adapter}::dbf($url)]]"
            }
            catch {
            puts $fd "set ${adapter}::dbsp($url) [list [set ${adapter}::dbsp($url)]]"
            }

	    set time [set ${adapter}::dbt($url)]
	    set time [date_string $time]
	    set time "<code>$time</code>&nbsp;&nbsp;"

	    puts $fd2 "<li>$time<a href='$url'>[set ${adapter}::dbs($url)]</a>"
	    
            incr n
            if {$n >= $g(max_articles)} {
                break
            }
            #puts $n=$g(max_articles)
        }
        close $fd
	puts $fd2 </ul>
        close $fd2

        write_xml_file $adapter $list
        if {[info exists ${adapter}::h(subpages)]} {
            foreach subpageinfo [set ${adapter}::h(subpages)] {
                write_xml_file $adapter $list $subpageinfo
            }
        }


        xlog 2 "... written $n articles [clock format [clock seconds] -timezone :US/Pacific]"
        if {[info exists env(DEBUG_NO_LOOPS)] &&
            (![info exists env(DEBUG_ARTICLE)] || "$env(DEBUG_ARTICLE)" == "")} {
            puts "env(DEBUG_NO_LOOPS) exists ... exiting 2"
            exit
        }
    }
}

proc write_xml_file {adapter list {subpageinfo {}}} {
    global g

    set subpage       [lindex $subpageinfo 0]
    set subpage_title [lindex $subpageinfo 1]

    set fd [open [adapter_xml_file $adapter $subpage] w+]
    fconfigure $fd -encoding utf-8	
    set out {<?xml version="1.0" encoding="utf-8"?>
<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">
  <channel>
    <title>DESC</title>
    <link>URL</link>
    <description>DESC</description>
    <dc:language>LANG</dc:language>
    <pubDate>DATE</pubDate>
    <sy:updatePeriod>hourly</sy:updatePeriod>
    <sy:updateFrequency>12</sy:updateFrequency>
    <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>
    }

    set date [clock_format [clock seconds]]
    set title "[set ${adapter}::h(desc)]$subpage_title"
    xlog 2 "${adapter} -- writing $title"
    regsub -all DATE        $out $date out
    regsub -all LANG        $out [set ${adapter}::h(lang)]  out
    regsub -all DESC        $out $title out
    regsub -all URL         $out [set ${adapter}::h(url)]  out

    puts $fd $out

    set n 0
    set lang [set ${adapter}::h(lang)]
    foreach url $list {
        set mysubpage {}
        if {[info exists ${adapter}::dbsp($url)]} {
            set mysubpage [set ${adapter}::dbsp($url)]
        }
        if {$subpage != $mysubpage} {
            continue
        }
        #xlog 3 "... creating [set ${adapter}::dbs($url)] - $url"
        set title [set ${adapter}::dbs($url)]
        set date [set ${adapter}::dbt($url)]
        set data [set ${adapter}::dbc($url)]

        set filtered 0
        catch {
            set filtered [set ${adapter}::dbf($url)]
        }
        if {$filtered == 1} {
            xlog 2 "${adapter} --- $title"
            continue
        }

        set data "<div lang=\"$lang\" xml:lang=\"$lang\">$data</div>"
        set newitem [makeitem $title $url $data $date]

        puts $fd $newitem
        incr n
        if {$n >= $g(max_articles)} {
            break
        }
        xlog 2 "${adapter} [format %3d $n] [date_string $date] $title"
    }
    puts $fd {</channel></rss>}
    close $fd
}

proc redirect_images {url data} {
    set pat {<img[^>]*src=[\"\']([^\"\']*)[\"\'][^>]*>}
    while {[regexp -nocase $pat $data dummy img]} {
	set img [redirect_image $img $url]
	regsub -all "\\\\" $img {\\\\} img
	regsub -all {&} $img {\\\&} img
	regsub -nocase $pat $data "\n<xxximg src='$img'>\n" data
    }
    regsub -all "<xxximg " $data "<img " data

    return $data
}

proc do_exit {} {
    xcatch {db_sync_all_to_disk}
    exit
}

main
