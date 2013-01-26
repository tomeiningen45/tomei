#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/tiexue
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------
proc compare_tiexue_id {a b} {
    if {[regexp {_([0-9]+)_} $a dummy ia] &&
        [regexp {_([0-9]+)_} $b dummy ib]} {
        return [compare_integer $ia $ib]
    } else {
        return 0
    }
}
proc compare_tiexue_date {a b} {
    set linka [lindex $a 0]
    set linkb [lindex $b 0]

    set filea [getcachefile $linka]
    set fileb [getcachefile $linkb]

    return [compare_file_date $filea $fileb]
}

proc update {} {
    global datadir

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>tiexue</title>  
    <link>http://mil.tiexue.net</link>  
    <description>DESC</description>  
    <dc:language>LANG</dc:language>  
    <pubDate>DATE</pubDate>  
    <dc:date>DATE</dc:date>  
    <sy:updatePeriod>hourly</sy:updatePeriod>  
    <sy:updateFrequency>1</sy:updateFrequency>  
    <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>  
    }

    set date [clock format [clock seconds]]
    regsub -all DATE        $out $date out
    regsub -all LANG        $out zh    out
    regsub -all DESC        $out tiex  out

    set data [wget http://mil.tiexue.net/ gb2312]

    set list ""
    foreach line [makelist $data "href=\"http://bbs.tiexue.net/post2"] {
        if {[regexp {^(_[0-9]+_1.html)\"[^>]*>([^<]+)</a>} $line dummy link title]} {
            if {![info exists seen($link)]} {
                set seen($link) 1
                lappend list [list $link $title]
            }
        }
    }

    set list [lrange [lsort -decreasing -command compare_tiexue_id $list] 0 60]

    # (2) Download all news (older first)
    #     Note: article number is not reliable for determining date ...
    foreach item [lreverse $list] {
        set link  [lindex $item 0]
        set title [lindex $item 1]

        #puts "$link = $title"

        set localname $link
        set link http://bbs.tiexue.net/post2$link
        set fname [getcachefile $localname]

        if {![file exists $fname]} {
            set needwait 1
        } else {
            set needwait 0
        }

        set started [now]
        puts -nonewline .
        flush stdout
        set data [getfile $link $localname gb2312]

        if {$needwait} {
            # sleep long enough for the file mtime to be different
            while {[now] - $started < 2} {
                after 100
            }
        }
    }
    puts ""

    if 0 {
        foreach item $list {
            set link [lindex $item 0]
            set title [lindex $item 1]
            puts "$link = $title"
        }
    }

    # (3) Create Feed (sort by file access date)

    foreach item [lsort -decreasing -command compare_tiexue_date $list] {
        set link  [lindex $item 0]
        set title [lindex $item 1]

        set localname $link
        set link http://bbs.tiexue.net/post2$link
        set fname [getcachefile $localname]
        set date [file mtime $fname]

        set data [getfile $link $localname]

        set pubtime ""
        regexp {20[0-9][0-9]/[0-9]+/[0-9]+ ..:..:..} $data pubtime
        puts ==$pubtime

        if {[regexp {<div id="contentstopbar" class="bt">(.*)<div id="OpThreadInfo"} $data dummy data]} {
            # good
        } else {
            set title "@@$title"
            set data "-unparsable- $link"
        }

        puts "$link = [clock format $date] $title"

        set data "<div lang=\"zh\" xml:lang=\"zh\">$pubtime $data</div>"
        append out [makeitem $title $link $data $date]
    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update