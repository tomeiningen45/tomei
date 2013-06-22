#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/cnbeta
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc update {} {
    global datadir env

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>cnbeta</title>  
    <link>http://cnbeta.com</link>  
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
    regsub -all DESC        $out 6prk  out

    set newlinks {}

    set max 600
    if {[info exists env(CNBETA_MAX)]} {
        set max $env(CNBETA_MAX)
    }

    set n 0
    foreach {title link description pubdate} [extract_feed http://cnbeta.com/backend.php] {
        if {![regexp {([0-9]+)[.]htm} $link dummy localname]} {
            continue
        }

        puts -nonewline $link
        flush stdout
        set started [now]

        set fname [getcachefile $localname]
        set data [getfile $link $localname utf-8]
        puts "  [expr [now] - $started] secs"

        set comments "【<a href=$env(WEB2RSSHTTP)cnbeta_comments/$localname.html>网友评论</a>】"

        if {[regexp {<div class="content">.*<div class="clear"></div>} $data]} {
            regsub {.*<div class="content">} $data "" data
            regsub {<div class="clear"></div>.*} $data "" data
            set data "<div lang=\"zh\" xml:lang=\"zh\">${comments}$data</div>"
            set description $data
        } else {
            puts "-- failed to parse contents"
            set title "@@$title"
        }

        #puts $data
        #exit
        append out [makeitem $title $link $description $pubdate]
        catch {
            lappend newlinks [clock scan $pubdate] $link
        }

        incr n
        if {$n >= $max} {
            break
        }
    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd

    set links [save_links $datadir $newlinks 200]
    puts "cnbeta: [llength $links] comments to update"
    # update_comments $datadir $links
}


update