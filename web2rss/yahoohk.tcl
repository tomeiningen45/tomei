# @rss-nt-adapter@

namespace eval yahoohk {
    proc init {first} {
        variable h
        set h(lang)  zh
        set h(desc)  雅虎香港新聞
        set h(url)   https://hk.news.yahoo.com/
    }

    proc update_index {} {
        ::schedule_read yahoohk::parse_index https://hk.news.yahoo.com
        ::schedule_read yahoohk::parse_index https://hk.news.yahoo.com/supplement
        ::schedule_read yahoohk::parse_index https://hk.news.yahoo.com/most-popular
    }

    proc parse_index {index_url data} {
        set list {}

        foreach line [makelist $data {<a href=\"}] {
            if {[regexp {^([^>\"]+[-][0-9]+[.]html)\"} $line dummy article_url]} {
                if {![info exists seen($article_url)]} {
                    set seen($article_url) 1
                    #puts $article_url
                    lappend list $article_url
                }
            }
        }
        foreach line [makelist $data {\"url\":\"}] {
            if {[regexp {^([^>\"]+[-][0-9]+[.]html)\"} $line dummy article_url]} {
                set article_url [subst $article_url]
                if {![info exists seen($article_url)]} {
                    #puts $article_url
                    set seen($article_url) 1
                    lappend list $article_url
                }
            }
        }

        foreach article_url [lsort -dictionary $list] {
            if {![regexp {^((https://)|(http://))} $article_url]} {
                set article_url https://hk.news.yahoo.com${article_url}
            }
            if {![db_exists yahoohk $article_url]} {
                ::schedule_read yahoohk::parse_article $article_url
                incr n
                if {$n >= 15} {
                    # dont access the web site too heavily
                    break
                }
            }
        }
    }

    proc consolidate_and_deduplicate_images {data} {
        set images {}
        set pat {<img[^>]*src="([^>\"]+)"[^>]*>}
        while {[regexp $pat $data dummy loc]} {
            if {[regexp {[.]png} $loc]} {
                regsub $pat $data "<IMG src=\"$loc\">" data
            } else {
                if {![info exists seen($loc)]} {
                    append images "<img src=\"$loc\"><br><br>"
                    set seen($loc) 1
                }
                regsub $pat $data "" data
            }
        }

        if {"$images" != {}} {
            set pats {
                {</figure>}
                {<div class="caas-img-container"[^>]*>}
            }
            set sub 0
            set x 0
            foreach pat $pats {
                incr x
                if {[regexp $pat $data]} {
                    regsub $pat $data \ufff0 data
                    set n [string first \ufff0 $data]
                    set data [string replace $data $n $n $images]
                    set sub 1
                    break
                }
            }
            if {!$sub} {
                append data "<p>$images"
            }
        }
        return $data
    }
    
    proc parse_article {url data} {
        set title ""
        regexp {<title>([^<]+)</title>} $data dummy title
        regsub {[ -]*雅虎香港新聞} $title "" title
        
        regsub {<header><h1>([^<]+)</h1></header>} $data "" data
        regsub {.*<article} $data "<span " data
        regsub {<div class=.canvas-share-buttons.*} $data "" data
        regsub {>相關內容<.*} $data ">" data
        regsub {>港聞<.*} $data ">" data
        regsub {>其他內容<.*} $data ">" data
        regsub {看更多文章<.*} $data "" data
        regsub {奇摩新聞歡迎您投稿.*} $data "" data
        regsub {>更多[^<]*報導<.*} $data ">" data
        regsub {更多追蹤報導<.*} $data "" data
        regsub {>睇更多<.*} $data ">" data
        regsub {> *是日精選<.*} $data ">" data
        
        regsub -all {<img[^>]* src="" } $data "<img " data
        regsub -all {<img[^>]* data-src=} $data "<img src=" data

        regsub -all {<noscript[^>]*>(<img [^<]+>)</noscript>} $data "\\1" data

        regsub -all "<br>\[ \n\t\]*<br>" $data "<br><br>" data
        regsub -all "<br>(<br>)+" $data "<br><br>" data

        set data [noscript $data]
        if {[regexp {class="caas-img"} $data]} {
            set data [consolidate_and_deduplicate_images $data]
        }

        regsub -all {<figure[^>]*>} $data "" data
        regsub -all {style="[^\"]+"} $data "" data


        regsub -all {<ul class="caas-carousel-slides">} $data "" data
        regsub -all {<li class="caas-carousel-slide">} $data "" data


        regsub -all {<a[^>]*prev-button[^>]*>} $data "" data
        regsub -all {<a[^>]*next-button[^>]*>} $data "" data
        regsub -all {<svg[^>]*>} $data "" data
        regsub -all {<path[^>]*>} $data "" data

        #puts $data
        #puts ""
        #puts $url
        #exit
        save_article yahoohk $title $url $data
    }
}
