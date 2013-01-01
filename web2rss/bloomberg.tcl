#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/bloomberg
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
    set url [lindex $argv 1]

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>TITLE</title>  
    <link>LINK</link>  
    <description>DESC</description>  
    <pubDate>DATE</pubDate>  
    <dc:date>DATE</dc:date>  
    <sy:updatePeriod>hourly</sy:updatePeriod>  
    <sy:updateFrequency>1</sy:updateFrequency>  
    <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>  
    }

    puts "   >>>>>>>>>>> Syncing Bloomberg $name"

    set data [wget $url]
    set title "Bloomberg - $url"
    regexp {<title>([^<]+)</title} $data dummy title
    
    set date [clock format [clock seconds]]
    regsub -all & $title "\\\\&amp;" tit

    regsub -all LINK        $out $url  out
    regsub -all DATE        $out $date out
    regsub -all DESC        $out $tit  out
    regsub -all TITLE       $out $tit  out

    puts "Feed title = $tit"

    set lastdate 0xffffffff

    foreach item [makelist $data {<a href=}] {
        if {[regexp {^"/([^<]+[.]html)"[^>]*data-type="Story"} $item dummy link] &&
            [regexp {>([^<]+)</a>} $item dummy title]} {
        } else {
            continue;
        }

        regsub -all {&amp;} $title \\& title
        regsub -all {&quot;} $title \" title
        regsub -all {&#39;} $title {'} title

        set link http://www.bloomberg.com/$link

        if {![regexp {/(20..-..-../[^/]+[.]html)$} $link dummy localname]} {
            continue
        }
        regsub / $localname - localname

        set fname [getcachefile $localname]
        set data [getfile $link $localname]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        if {[regexp {<div id="story_display">(.*)<div id="related_news_bottom"} $data dummy data]} {
            regsub {<div class="story_inline[^>]*">.*} $data "" data
            regsub -all {<!\[CDATA\[} $data "" data
            regsub -all {//\]\]>} $data "" data
            regsub {<script type="text/javascript">.*} $data "" data
            #puts $data
        } else {
            set title "@@$title"
            set data "-unparsable- $link"
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