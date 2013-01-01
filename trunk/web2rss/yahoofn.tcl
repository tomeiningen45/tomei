#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/yahoofn
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc update {} {
    global datadir argv

    set name [lindex $argv 0]
    set title [lindex $argv 1]
    set url [lindex $argv 2]

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>TITLE</title>  
    <link>http://finance.yahoo.com/news/</link>  
    <description>DESC</description>  
    <pubDate>DATE</pubDate>  
    <dc:date>DATE</dc:date>  
    <sy:updatePeriod>hourly</sy:updatePeriod>  
    <sy:updateFrequency>1</sy:updateFrequency>  
    <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>  
    }

    regsub -all & $title "\\\\&amp;" tit
    set date [clock format [clock seconds]]
    regsub -all DATE        $out $date  out
    regsub -all DESC        $out $tit out
    regsub -all TITLE       $out $tit out

    puts "   >>>>>>>>>>> Syncing $name == $title"

    set data [wget $url]

    set lastdate 0xffffffff

    foreach item [makelist $data <item>] {
        if {[regexp {<link>([^<]+)</link>} $item dummy link] &&
            [regexp {<title>([^<]+)</title>} $item dummy title]} {
        } else {
            continue;
        }

        regsub -all {&amp;} $title \\& title
        regsub -all {&quot;} $title \" title
        regsub -all {&#39;} $title {'} title

        if {![regexp {/([^/]+[.]html)$} $link dummy localname]} {
            continue
        }

        set fname [getcachefile $localname]
        set data [getfile $link $localname]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        if {[regexp {<div class="yom-mod yom-art-content ">(.*)<!-- END article -->} $data dummy data]} {
            regsub {<div class="yom-mod yom-follow".*} $data "" data
            regsub {<p class="first">By[^<]*</p>} $data "" data
           # puts $data
        } else {
            if {[regexp {(.*</item>)} $item "" item]} {
                regsub <title> $item "<title>@@" item
                regsub -all {<media[^>]*>} $item "" item
                regsub -all {</media[^>]*>} $item "" item
                append out "<item>$item"
            }
            puts "@@$title==$link"
            continue
        }

        puts $title==$link

        append out [makeitem $title $link $data $date]
    }

    append out {</channel></rss>}

    set fd [open ${datadir}_${name}.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update