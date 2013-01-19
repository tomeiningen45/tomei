#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/zasshi
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------
proc my_compare {a b} {
    global seen local

    set mtimea [file mtime [getcachefile $local($a)]]
    set mtimeb [file mtime [getcachefile $local($b)]]

    set numa $mtimea
    set numb $mtimeb

    regexp {/([0-9]+)/} $a dummy numa
    regexp {/([0-9]+)/} $b dummy numb

    if {$mtimea > $mtimeb} {
        return 1
    } elseif {$mtimea < $mtimeb} {
        return -1
    } elseif {$numa > $numb} {
        return 1
    } elseif  {$numa < $numb} {
        return 1
    } else {
        return 0
    }
}

proc update {} {
    global datadir seen local seenx

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>TITLE</title>  
    <link>http://www.iza.ne.jp/news/</link>  
    <description>DESC</description>  
    <pubDate>DATE</pubDate>  
    <dc:date>DATE</dc:date>  
    <sy:updatePeriod>hourly</sy:updatePeriod>  
    <sy:updateFrequency>1</sy:updateFrequency>  
    <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>  
    }

    set date [clock format [clock seconds]]

    set tit "Yahoo Zasshi"
    regsub -all DATE        $out $date out
    regsub -all DESC        $out $tit  out
    regsub -all TITLE       $out $tit  out


    # (1) Get index of all news (skip duplicates)
    # sort the list in order of interest
    set data [wget http://zasshi.news.yahoo.co.jp/newly/ euc-jp]
    regsub {<li class="ymuiRanking ymuiRank01">.*} $data "" data

    set list {}
    foreach item [makelist $data {<li class="ymuiArrow1">}] {
        if {[regexp {^<a href="([^>]+)">([^<]+)</a>} $item dummy link title]} {
            set src ""
            regexp {<a href="[^>]+http://zasshi.news.yahoo.co.jp/list/[?]m=[^>]+">([^<]+)</a>} $item dummy src
            set image ""
            if {[regexp {<span class="ymuiPhoto" title="写真">} $item]} {
                set image " (画)"
            }

            if {"$src" != ""} {
                set title "$title$image - $src"
            }

            set skipped 0
            foreach skip {
                [-]davinci
                [-]pseven[-]ent
                [-]pseven[-]soc
                [-]sportiva
            } {
                if {[regexp $skip $link]} {
                    set skipped 1
                }
            }
            if {$skipped == 0} {
                lappend list [list $link $title]
            }
        }
    }

    #foreach item $list {
    #    set title [lindex $item 1]
    #    puts $title
    #}
    #exit


    # (2) Download all news (older first)
    #     Note: article number is not reliable for determining date ...
    foreach item [lreverse $list] {
        set url [lindex $item 0]
        set title [lindex $item 1]
        set localname $url
        regsub .*a= $localname "" localname
        regsub {/$} $localname "" localname
        regsub -all / $localname - localname

        set local($url) $localname
        set fname [getcachefile $localname]
        if {![file exists $fname]} {
            set needwait 1
        } else {
            set needwait 0
        }

        #puts $url=$title

        set started [now]
        puts -nonewline .
        flush stdout
        set data [getfile $url $localname euc-jp]

        if {$needwait} {
            while {[now] - $started < 2} {
                after 100
            }
        }
    }
    puts ""

    # Write RSS list (latest first)
    foreach item $list {
        set url [lindex $item 0]
        set title [lindex $item 1]

        set localname $local($url)

        set fname [getcachefile $localname]
        set data [getfile $url $localname euc-jp]
        set date [file mtime $fname]

        regsub -all {&amp;} $title \\& title
        regsub -all {&quot;} $title \" title
        regsub -all {&#39;} $title {'} title

        set images ""
        if {[regexp {<div class=.ynDetailPhoto} $data]} {
            if {[regexp {<img src="http://[^>]*yimg.jp/[^>]*.jpg"} $data images]} {
                append images ">"
                set images "<div STYLE='float:left'>$images</div>"
            }
        }

        if {[regexp {<p class="ynDetailText">(.*)} $data dummy data]} {
            regsub {<div class="ynDetailRelArticle">.*} $data "" data
            regsub {<div class="fbSocialMod">.*} $data "" data
            set data $images$data
        } else {
            set title "@@$title"
            set data "-unparsable- $link"
        }

        if {"$images" != ""} {
            append title " - (画)"
        }

        puts $title==$url
        set data "<div lang=\"ja\" xml:lang=\"ja\">$data</div>"
        append out [makeitem $title $url $data $date]
    }

    append out {</channel></rss>}

    set fd [open ${datadir}.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

proc get_images {data localname} {
    set fname [getcachefile $localname.imgcache]
    if {[file exists $fname]} {
        set fd [open $fname]
        set data [read $fd]
        close $fd
        return $data
    }

    set queue {}
    if {[regexp {div class="mainPhoto"><span><a href="([^>]+)">} $data dummy link]} {
        set link http://www.iza.ne.jp$link
        lappend queue $link
        set seen($link) 1
    } else {
        return ""
    }

    set result ""

    set pass 0
    while {[llength $queue] > 0} {
        incr pass
        set q $queue
        set queue {}

        foreach link $q {
            set done($link) 1
            set data [wget $link]

            set pat {<li><a href="([^>]+/slideshow/[0-9]+/)"><img class="content_img"}

            if {[regexp {<img class="content_img pis_image" src="([^"]+)" alt="([^"]+)"} $data dummy img text]} {
                append result "<br><img src=$img><br>$text<p>\n"
            }
            while {[regexp $pat $data dummy link]} {
                #puts $pass=$link
                regsub $pat $data XXX data
                set link http://www.iza.ne.jp$link
                if {![info exists seen($link)]} {
                    lappend queue $link
                    set seen($link) 1
                }
            }
        }
    }
    set result "<hr><center>$result</center><hr>"
    #puts $result
    set fd [open $fname w+]
    puts $fd $result
    close $fd
    return $result
}

#get_images [wget http://www.iza.ne.jp/news/newsarticle/world/america/621516/]
#exit

update