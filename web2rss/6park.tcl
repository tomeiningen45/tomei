# @rss-nt-adapter@
#
#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
namespace eval 6park {

package require ncgi

proc init {first} {
    global g h
    #puts [namespace current]
    #parray g
    #parray h
}

proc update_index {} {
    ::schedule_read 6park::parse_index http://news.6park.com/newspark/index.php gb2312
}

proc parse_index {url data} {

    regsub {<div id="d_list"} $data "" data
    regsub {<div id="d_list_foot"} $data "" data

    foreach line [makelist $data <li>] {
        incr n
        if {[regexp {href="([^>]+)"} $line dummy link] &&
            [regexp {>([^<]+)<} $line dummy title]} {

        }

        if {![regexp {nid=([0-9]+)$} $link dummy id]} {
            continue;
        }

        if {![regexp {http[a-z]*://news.toutiaoabc.com} $link]} {
            continue
        }

        ::schedule_read [list 6park::get_toutiaoabc $id $title] $link gb2312
        if {$n > 10} {
            break
        }
    }
    #exit
}

proc get_toutiaoabc {id title url data} {
    puts $title==$url==[string len $data]

    set from ""
    regexp {新闻来源: ([^ ]+)} $data dymmy from

    regsub {.*<div id="mainContent">} $data "" data
    regsub {.*<div id='shownewsc' style="margin:15px;">} $data "" data
    regsub {<table class='xianhua_jidan'.*} $data "" data
    regsub {<a href=[^>]+target=_blank><img[^>]+转发本条新闻到微博'></a>} $data "" data

    set data [sub_block $data "<script" "</script>" ""]
    set data [sub_block $data {<ins class="adsbygoogle"} "</ins>" ""]=
    
    if {"$from" != ""} {
        set data "【$from】 $data"
    }

    # most of the center tags are wrong on 6park
    regsub -all <center> $data <noceneter> data
    regsub -all {align='center'} $data "" data

    # fix images
    regsub -all "src=\['\"\](\[^> '\"\]+)\['\"\]" $data src=\\1 data
    regsub -all {onload='javascript:if[(]this.width>600[)] this.width=600'} $data "" data

    if {0} {
        set pat {<img[^>]*src=(http://[^>]*.popo8.com/[^> ]+)[^>]*>}
        while {[regexp $pat $data dummy img]} {
            set imgfile 6park/foo.jpg
            set h1 http://freednsnow.no-ip.biz/webrss/$imgfile
        
            set i "<img onload='javascript:if(this.width>600) this.width=600' src=XXX border='0'>"
            regsub XXX $i $img img0
            regsub XXX $i http://freednsnow.no-ip.biz/webrss/$imgfile img1
            regsub XXX $i http://127.0.0.1/webrss/$imgfile img2

            regsub $pat $data $img0$img1$img2 data
        }
    }

    set data "<div lang=\"zh\" xml:lang=\"zh\">$data</div>"

    global count
    incr count
    if {$count > 2} {
        set fd [open [test_html_file] w+]

        puts $fd {<html>
            <head>
            <META HTTP-EQUIV="content-type" CONTENT="text/html; charset=utf-8"></head>}
    
        puts $fd $data
        close $fd
        puts $data
        exit
    }
}

if 0 {

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------
 
proc update {} {
    global datadir env

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

    set data [wget http://news.6park.com/newspark/index.php gb2312]

    regsub {<div id="d_list"} $data "" data
    regsub {<div id="d_list_foot"} $data "" data

    set max 50
    catch {
        set max $env(MAXRSS)
    }
    set n 0
    set lastdate 0xffffffff

    foreach line [makelist $data <li>] {
        incr n
        if {$n > $max} {
            break
        }

        if {[regexp {href="([^>]+)"} $line dummy link] &&
            [regexp {>([^<]+)<} $line dummy title]} {
            set link http://news.6park.com/newspark/$link
            puts $title==$link
        }

        if {![regexp {nid=([0-9]+)$} $link dummy id]} {
            continue;
        }
        set fname [getcachefile $id]

        set data [getfile $link [file tail $fname] gb2312]
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
        regsub -all {onload[ ]*=} $data "xx=" data
        regsub {.*</script>} $data "" data 

        set id ""
        regexp {nid=([0-9]+)$} $link dummy id
        set comment " 【<a href=http://news.6park.com/newspark/index.php?act=newsreply&nnid=${id}&nid=${id}>网友评论</a>】 "
        set data "$comment $data"

        if {"$from" != ""} {
            set data "【$from】 $data"
        }

        # fix images
        regsub -all "src=\['\"\](\[^> '\"\]+)\['\"\]" $data src=\\1 data

        set pat {<img[^>]*src=(http://[^>]*.popo8.com/[^> ]>)}
        while {[regexp $pat $data dummy img]} {
            puts $img
            set rep src=\"http://freednsnow.no-ip.biz:9015/cgi-bin/im.cgi/
            append rep "a=[ncgi::encode $img]/"
            append rep "b=[ncgi::encode $link]\""
            regsub $pat $data $rep data
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
}
}
