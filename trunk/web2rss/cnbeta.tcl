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
# to-be common scripts
#----------------------------------------------------------------------

# return a list of {title link description pubdate ...}
proc extract_feed {url} {
    set data [wget $url]
    set list ""
    foreach part [makelist $data <item>] {
        if {![regexp {<title>(.*)</title>} $part dummy title]} {
            continue
        }
        if {![regexp {<link>(.*)</link>} $part dummy link]} {
            continue
        }
        if {![regexp {<description>(.*)</description>} $part dummy description]} {
            continue
        }
        if {![regexp -nocase {<pubdate>(.*)</pubdate>} $part dummy pubdate]} {
            continue
        }

        lappend list $title $link $description $pubdate
    }

    return $list
}

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc update {} {
    global datadir

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

    set lastdate 0xffffffff

    foreach {title link description pubdate} [extract_feed http://cnbeta.com/backend.php] {
        puts $link
        if {![regexp {([0-9]+)[.]htm} $link dummy localname]} {
            continue
        }

        set fname [getcachefile $localname]
        set data [getfile $link $localname gb2312]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        if {[regexp {.*<div id="news_content">.*<div class="digbox">} $data]} {
            regsub {.*<div id="news_content">} $data "" data
            regsub {<div class="digbox">.*} $data "" data
            set description $data
        } else {
            puts "-- failed to parse contents"
        }

        #puts $data
        #exit
        append out [makeitem $title $link $description $pubdate]
    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update