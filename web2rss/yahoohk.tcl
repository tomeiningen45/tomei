#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/hkyahoo
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------
package require ncgi

proc update {} {
    global datadir env

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>yahou_hk</title>  
    <link>http://yahou_hk.com</link>  
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

    set data [wget https://hk.news.yahoo.com/business/archive/]

    regsub {.*<div class="yog-col yog-11u yom-primary">} $data "" data
    regsub {<div class="yog-col yog-8u yog-col-last yom-secondary">.*} $data "" data

    set newlinks {}
    set lastdate 0xffffffff

    set n 1
    foreach line [makelist $data {<h4><a href=}] {
        if {[regexp {"(/[^>]+[.]html)" alt="([^>\"]+)"} $line dummy link title]} {
            puts $n>>>>>>>>>>>>>>$title==$link
        } else {
            continue
        }
        set link http://hk.news.yahoo.com/$link
        set fname [getcachefile $link]
        set data [getfile $link [file tail $link]]

        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
            file mtime $fname $date
        }
        set lastdate $date

        set gotit 0

        set comments ""
        if {0} {
        if {[regexp {<link rel="canonical" href="([^>]+)"/>} $data dummy canlink]} {
            puts $canlink
            set cmt http://freednsnow.no-ip.biz:9015/cgi-bin/hky.cgi?a=$canlink
            puts $cmt
            set comments "【<a href=$cmt>网友评论</a>】"
        }
        }
        
        if {[regsub {.*<p class="first">} $data "" data] && 
            [regsub {<div class="yom-mod yom-follow".*} $data "" data]} {
            set gotit 1
        }

        if {[regsub {.*<div class="yom-mod yom-videometadata-desc">} $data "" data] &&
            [regsub {<div class="yom-mod yom-videometadata-prvdr">.*} $data "" data]} {
            set gotit 1
        }

        regsub {<!-- google_ad_section_end --></div></div>.*} $data "" data

        if {$gotit} {
            set data "<div lang='zh' xml:lang='zh'>$comments $data</div>"
            append out [makeitem $title $link $data $date]
            catch {
                lappend newlinks $date $link
            }
        }

        if {$n > 5} {
            #break
        }
        incr n
    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd

    set links [save_links $datadir $newlinks 40]
    puts "hkyahoo: [llength $links] comments to update"

}

update
