#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/6park
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc update {} {
    global datadir

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>6park</title>  
    <link>http://6park.com</link>  
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

    set data [wget http://www.6park.com/news/multi1.shtml gb2312]

    regsub {.*<td class=td1>} $data "" data
    regsub {</table>.*} $data "" data

    set lastdate 0xffffffff

    foreach line [makelist $data <li>] {
        if {[regexp {href="([^>]+)"} $line dummy link] &&
            [regexp {>([^<]+)<} $line dummy title]} {
            puts $title==$link
        }

        set fname [getcachefile $link]

        set data [getfile $link [file tail $link] gb2312]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        set from ""
        regexp {新闻来源: ([^ ]+)} $data dymmy from

        regsub {.*<!--bodybegin-->} $data "" data
        regsub {<!--bodyend-->.*} $data "" data
        regsub -all {<font color=E6E6DD> www.6park.com</font>} $data "\n\n" data
        regsub -all {onclick=document.location=} $data "xx=" data
        regsub {.*</script>} $data "" data 

        if {"$from" != ""} {
            set data "【$from】 $data"
        }
        set data "<div lang=\"zh\" xml:lang=\"zh\">$data</div>"
        append out [makeitem $title $link $data $date]

    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update