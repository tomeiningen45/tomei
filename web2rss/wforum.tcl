#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/wforum
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
    <title>wforum</title>  
    <link>http://wforum.com</link>  
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

    set data [wget http://bbs.wforum.com/wmf/ gb2312]

    if {![regsub {.*<td><table width='810' border='0' cellpadding='0' cellspacing='0' background='skin/001/img/f016.gif'>} $data "" data]} {
        puts "cannot get index header";
        return
    }
    regsub {</table>.*} $data "" data

    set data2 [wget http://www.wforum.com/news/headline/ gb2312]
    if {[regsub {.*../images/wforum_index_35.gif} $data2 "" data2] &&
        [regsub {<form target='_self'.*} $data2 "" data2] &&
        [regsub -all {<td aligh='left'>} $data2 "" data2]} {
        append data $data2
    }

    set lastdate 0xffffffff

    foreach line [makelist $data <td] {
        if {[regexp {<a href='([^']+)' title='([^']+)'} $line dummy link title]} {
            set type 1
        } elseif {[regexp {href='([^'>]+)'} $line dummy link] &&
            [regexp {>([^<]+)<} $line dummy title]} {
            set type 2
        } else {
            continue;
        }
        puts $type:$title==$link

        if {$type == 1} {
            set link http://www.wforum.com/news/headline/$link
            if {![regexp {id=([0-9]+)} $link dummy localname]} {
                continue
            }
            set localname $localname-news
        } else {
            set link http://bbs.wforum.com/wmf/$link
            if {![regexp {id=([0-9]+)} $link dummy localname]} {
                continue
            }
        }

        set fname [getcachefile $localname]
        set data [getfile $link $localname gb2312]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        if {$type == 1} {
            if {![regsub {.*正文</td>} $data "" data]} {
                puts "cannot get page header $link"
                continue
            }
            if {![regsub {<!-- Wforum_ROS_160x600 -->.*} $data "" data] ||
                ![regsub {<img src=.../images/text_jcwz.gif.*} $data "" data]} {
                puts "cannot get page tail $link"
                continue
            }
            regsub {<h3[^>]+>[^<]+</h3>} $data "" data
            regsub -all {<div id='div-gpt-ad-[^>]+>} $data "<DIV>" data
            #regsub -all {<script [^>]+>} $data "" data
            #puts $data
            #exit
        } else {
            if {![regsub {.*<td width="640" height="46" align="center" class="trd_subject" id="trd_subject">}  \
                  $data "" data]} {
                puts "cannot get page header $link"
                continue
            }
            if {![regsub {<input type="hidden" name="btrd_content" id="btrd_content" value="">.*} \
                  $data "" data] &&
                ![regsub {<input name='user_name.*} $data "" data]} {
                puts "cannot get page tail $link"
                continue
            }
        }

        regsub {<tr align="left" id="tr_acc_display">.*} $data "" data
        regsub -all {<img src=.skin[^>]*>} $data "" data
        regsub -all {<img src="[1-9]+.gif">} $data "" data
        regsub {<td height="13"></td>} $data "" data
        regsub {<form[^>]*>} $data "" data
        regsub {.*class="trd_info">发送悄悄话</a></td>} $data "" data
        regsub {.*来源：<a[^>]*>[^<]*</a>} $data "" data
        #regsub -all {&nbsp;} $data " " data
        regsub {</p><p><br /></p><a></a> <div> <div> <p>.nbsp;</p> <p>} $data "" data

        regsub -nocase -all {<img([^>]+)width} $data {<img\1xwidth} data
        regsub -nocase -all {<img([^>]+)height} $data {<img\1xheight} data

        regsub -all {<img } $data {<img STYLE="max-width:80%" } data
        regsub -all {href='bbsviewer.php} $data {href='http://bbs.wforum.com/wmf/bbsviewer.php} data

        #puts $data
        #exit
        append out [makeitem $title $link $data $date]

    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update