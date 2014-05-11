set forum     [lindex $argv 0]
set forumurl  [lindex $argv 1]
set forumname [lindex $argv 2]
if {$forumname == ""} {
    set forumname $forum
}
#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/6park-$forum
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------
package require ncgi
 
proc update {} {
    global datadir env forum forumname forumurl

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>DESC</title>  
    <link>URL</link>  
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
    regsub -all DESC        $out 6prk-$forumname  out
    regsub -all URL         $out $forumurl  out

    set data [wget $forumurl gb2312]

    regsub {<div id="d_list"} $data "" data
    regsub {<div id="d_list_foot"} $data "" data

    set max 50
    catch {
        set max $env(MAXRSS)
    }
    set n 0
    set lastdate 0xffffffff

    foreach line [makelist $data {(<ul>.			<li>)|(<br></li><li><a)}] {
        incr n
        if {$n > $max} {
            break
        }

        if {[regexp {href="([^>]+)"} $line dummy link] &&
            [regexp {>([^<]+)<} $line dummy title]} {
            set link $forumurl/$link
            puts $title==$link
        }

        if {![regexp {tid=([0-9]+)$} $link dummy id]} {
            continue;
        }
        set fname [getcachefile $id]

        set data [getfile $link [file tail $fname] gb2312]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        regsub {.*<!--bodybegin-->} $data "" data
        regsub {<!--bodyend-->.*} $data "" data
        regsub -all {<font color=E6E6DD> www.6park.com</font>} $data "\n\n" data
        regsub -all {onclick=document.location=} $data "xx=" data
        regsub -all {onload[ ]*=} $data "xx=" data
        regsub {.*</script>} $data "" data 

        # fix images
        regsub -all "src=\['\"\](\[^> '\"\]+)\['\"\]" $data src=\\1 data

        set pat {src=(http://www.popo8.com/[^> ]+)}
        while {[regexp $pat $data dummy img]} {
            puts $img
            set rep src=http://freednsnow.no-ip.biz:9015/cgi-bin/im.cgi?
            append rep "a=[ncgi::encode $img]\\&"
            append rep "b=[ncgi::encode $link]"
            regsub $pat $data $rep data
        }

        if {[regexp <pre> $data] && ![regexp </pre> $data]} {
            regsub <pre> $data " " data
        }
        regsub -all "<img " $data " <img " data
        set data "<div lang=\"zh\" xml:lang=\"zh\">$data</div>"
        regsub -all {[&]} $link "&amp;" link
        append out [makeitem $title $link $data $date]
    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update 
