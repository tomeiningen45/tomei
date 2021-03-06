#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/gooblog
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc update {} {
    global datadir argv

    set name  [lindex $argv 0]
    set tit   [lindex $argv 1]
    set url   [lindex $argv 2]

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

    set date [clock format [now]]

    set tit "gooブログ - $tit"
    regsub -all LINK        $out $url  out
    regsub -all DATE        $out $date out
    regsub -all DESC        $out $tit  out
    regsub -all TITLE       $out $tit  out

    puts "   >>>>>>>>>>> Syncing Gooblog $name : $tit : $url"

    foreach {title link description pubdate} [extract_feed $url] {
        set localname $link
        regsub {http://blog.goo.ne.jp/} $localname "" localname
        regsub -all / $localname - localname

        regsub -all {&amp;} $title \\& title
        regsub -all {&quot;} $title \" title
        regsub -all {&#39;} $title {'} title

        #puts $link=$title=$localname
        set started [now]
        set data [getfile $link $localname euc-jp]

        if {[regexp {<!-- entry-body -->(.*)<!-- /entry-body -->} $data]} {
            # OK
        } else {
            foreach {beg end} {
                {<!--エントリー-->}
                {<!--/エントリー-->}

                {<!-- エントリー -->}
                {<!-- /エントリー -->}

                {<!-- Text -->}
                {<!-- /Text -->}

                {<!--main-->}
                {<!--/main-->}
            } {
                if {[regsub -all $beg $data {<!-- entry-body -->} data]} {
                     regsub -all $end $data {<!-- /entry-body -->} data
                    break;
                }
            }
        }

        set mainpage ""
        set mainname ""
        if {[regexp {<h1[^>]*><a href="(http://blog.goo.ne.jp/[^>]+)">([^<]+)</a></h1>} $data dummy mainlink mainname] ||
            [regexp {<a href="(http://blog.goo.ne.jp/[^>]+)" class="bTitleLink"><span class="bTitle">([^<]+)</span></a>} \
                 $data dummy mainlink mainname]} {
            #puts +++++$mainname
            set mainpage "【<a href='$mainlink'>$mainname</a>】"
        } else {
            puts @@NONAME=$link
        }

        if {[regexp {<!-- entry-body -->(.*)<!-- /entry-body -->} $data dummy data]} {
            regsub {<!-- /entry-body -->.*} $data "" data
            regsub {<rdf:RDF.*</rdf:RDF>} $data "" data

            regsub -all {<a href="(http://blogimg.goo.ne.jp/[^>]+)"><img src=[^>]+></a>} $data {<img src='\1'>} data

            regsub {<div align="right" class="etFoot"><span class="etCommentLink">.*} $data "" data

            set data $mainpage$data
            #puts $data
        } else {
            set title "@@$title"
            set data "-unparsable- $link"
        }

        puts "$mainname - $title: $link [expr [now] - $started]"

        append out [makeitem $title $link $data $pubdate]
    }

    append out {</channel></rss>}

    set fd [open ${datadir}_${name}.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update