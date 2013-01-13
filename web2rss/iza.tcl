#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/iza
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

    set tit "IZA News"
    regsub -all DATE        $out $date out
    regsub -all DESC        $out $tit  out
    regsub -all TITLE       $out $tit  out


    # (1) Get index of all news (skip duplicates)
    # sort the list in order of interest
    set order {}
    foreach index {
        http://www.iza.ne.jp/news/newsranking/hotnews/
        http://www.iza.ne.jp/news/event/allnews/
        http://www.iza.ne.jp/news/economy/allnews/
        http://www.iza.ne.jp/news/world/allnews/
        http://www.iza.ne.jp/news/natnews/allnews/
        http://www.iza.ne.jp/news/column/allnews/
    } {
        puts -nonewline "Iza Indexing $index: "
        flush stdout
        set data [wget $index]
        set list {}
        if {[regexp {<td class="link_type1 newsList_s1">} $data]} {
            foreach item [makelist $data {<td class="link_type1 newsList_s1">}] {
                if {[regexp {<a href="(/[^>]+/)">([^<]+)</a>} $item dummy url title]} {
                    lappend list $url $title
                }
                if {[llength $list] >= 40} {
                    break
                }
            }
        } elseif {[regexp {<span class="ranking_number">} $data]} {
            foreach item [makelist $data {<dt class=.izablog_rank}] {
                if {[regexp {<a href="(/[^>]+/)"><strong>([^<]+)</strong>} $item dummy url title]} {
                    lappend list $url $title
                }
            }
        } else {
            puts -nonewline " cannot categorize index"
        }
        puts " [expr [llength $list] / 2]"
        set n 0
        foreach {url title} $list {
            regexp {/([0-9]+)/} $url dummy numa

            if {![info exists seen($url)]} {
                if {![info exists seenx($numa)]} {
                    incr n
                    set seen($url) $title
                    set seenx($numa) $url
                    puts " ([format %2d $n]) $url: $title"
                    lappend order $url
                }
            } elseif {[string length $title] > [string length $seen($url)]} {
                set seen($url) $title
                puts "      $url: $title"
            }
        }
    }

    # (2) Download all news (older first)
    #     Note: article number is not reliable for determining date ...
    foreach url [lreverse $order] {
        set localname $url
        regsub ^/ $localname "" localname
        regsub {/$} $localname "" localname
        regsub -all / $localname - localname

        set local($url) $localname
        set fname [getcachefile $localname]
        if {![file exists $fname]} {
            set needwait 1
        } else {
            set needwait 0
        }

        set started [now]
        puts -nonewline .
        flush stdout
        set data [getfile http://www.iza.ne.jp$url $localname]

        if {$needwait} {
            while {[now] - $started < 2} {
                after 100
            }
        }
    }
    puts ""

    # (3) Determine order of articles in RSS feed (latest first)
    #     Note: article number is not reliable for determining date ...
    set order [lreverse [lsort -command my_compare $order]]
    set lastdate 0xffffffff

    foreach url $order {
        #puts "$url - $seen($url)"
        set title $seen($url)
        set localname $local($url)

        set fname [getcachefile $localname]
        set data [getfile $url $localname]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        if {[regexp {<title>([^<]+)</title>} $data dummy title]} {
            regsub {^「} $title "" title
            regsub {」：イザ！}  $title "" title
        }

        regsub -all {&amp;} $title \\& title
        regsub -all {&quot;} $title \" title
        regsub -all {&#39;} $title {'} title

        set images [get_images $data $localname]

        if {[regexp {<div id="newsText1" class="newsText">(.*)<p id="return2TextTop">} $data dummy data]} {
            if {[regsub -all {<p class="speech">関連記事</p>.*<span class="speech">記事本文の続き</span>} $data \uFFFF data] ||
                [regsub -all {<span class="speech">記事本文の続き</span>} $data \uFFFF data]} {
                set list [split $data \uFFFF]
                set data "[lindex $list 0]$images[lindex $list 1]"
            } else {
                append data $images
            }
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