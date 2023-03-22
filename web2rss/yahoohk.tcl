# @rss-nt-adapter@

namespace eval yahoohk {
    proc init {first} {
        variable h
        set h(lang)  zh
        set h(desc)  YHK
        set h(url)   https://hk.news.yahoo.com/
        set h(out)   yhk
	set h(max_articles)  [::get_debug_opt DEBUG_MAX_ARTICLES  20]
        set h(max_downloads) [::get_debug_opt DEBUG_MAX_DOWNLOADS 15]
    }

    proc update_index {} {
       #::schedule_read yahoohk::parse_index https://hk.news.yahoo.com
       #::schedule_read yahoohk::parse_index https://hk.news.yahoo.com/supplement
       #::schedule_read yahoohk::parse_index https://hk.news.yahoo.com/most-popular
        ::schedule_read yahoohk::parse_index https://hk.news.yahoo.com/archive
    }

    proc parse_index {index_url data} {
        variable h
        set list {}

        foreach line [makelist $data { href=\"}] {
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
                if {$n >= $h(max_downloads)} {
                    # dont access the web site too heavily
                    break
                }
            }
        }
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {article_url} {
        ::schedule_read yahoohk::parse_article $article_url
    }
    
    proc deduplicate_images {data} {
        set pat {<img[^>]*src="([^>\"]+)"[^>]*>}

        set loc {}
        while 1 {
            if {"$loc" == ""} {
                if {![regexp $pat $data dummy loc]} {
                    break
                }
                regsub $pat $data "<IMG src=\"\\1\">" data
            }
            if {[regexp {[.]png} $loc]} {
                set loc {}
                puts 1
                continue
            }            
            if {[regexp $pat $data dummy loc2]} {
                if {[string comp $loc $loc2] == 0} {
                    regsub $pat $data "<br>" data
                    set loc {}
                } else {
                    regsub $pat $data "<IMG src=\"\\1\">" data
                    set loc $loc2
                }
            } else {
                break
            }
        }
        return $data
    }
    
    proc parse_article {url data} {
        set title ""
        regexp {<title>([^<]+)</title>} $data dummy title
        regsub {[ -]*\u96C5\u864E\u9999\u6E2F\u65B0\u805E} $title "" title

        regsub {<header><h1>([^<]+)</h1></header>} $data "" data
        regsub {.*<article} $data "<span " data
        regsub {<div class=.canvas-share-buttons.*} $data "" data
        regsub {</article>.*} $data "" data
        regsub {>相關內容<.*} $data ">" data
        regsub {>港聞<.*} $data ">" data
        regsub {>其他內容<.*} $data ">" data
        regsub {看更多文章<.*} $data "" data
        regsub {奇摩新聞歡迎您投稿.*} $data "" data
        regsub {>更多[^<]*報導<.*} $data ">" data
        regsub {更多追蹤報導<.*} $data "" data
        regsub {>睇更多<.*} $data ">" data
        regsub {> *是日精選<.*} $data ">" data
        regsub {</p><p>原文標題.*} $data "" data
        regsub {分鐘文章} $data "分鐘文章<p>" data
        regsub {我們致力為用戶建立安全而有趣的平台.*我們暫時停用文章留言功能.*} $data "" data

        regsub -all {<img[^>]* src="" } $data "<img " data
        regsub -all {<img[^>]* data-src=} $data "<img src=" data
        regsub -all {<img[^>]* src=} $data "<img src=" data

        regsub -all {<noscript[^>]*>(<img [^<]+>)</noscript>} $data "\\1" data

        regsub -all "<br>\[ \n\t\]*<br>" $data "<br><br>" data
        regsub -all "<br>(<br>)+" $data "<br><br>" data

        set data [noscript $data]
        set data [deduplicate_images $data]

        regsub -all {<figure[^>]*>} $data "" data
        regsub -all {</figure[^>]*>} $data "\n" data
        regsub -all {style="[^\"]+"} $data "" data

        regsub -all {<ul class="caas-carousel-slides">} $data "" data
        regsub -all {<li class="caas-carousel-slide">} $data "" data

        regsub -all {<a[^>]*prev-button[^>]*>} $data "" data
        regsub -all {<a[^>]*next-button[^>]*>} $data "" data
        set data [sub_block $data {<svg[^>]*>} {</svg>} ""]
        regsub -all {<path[^>]*>} $data "" data

        regsub -all {<figcaption[^>]*>} $data "\n<i><br><font size=-1>\u2605 " data
        regsub -all "</figcaption" $data "</font></i><br" data
        regsub {<div id="YDC-Bottom".*} $data "" data
        regsub {&lt;!--AD--&gt;&lt;.*} $data "" data

        regsub -all {<span[^>]*>查看相片</span>} $data "" data
        regsub -all {<div[^>]*>} $data <span> data
        regsub -all {</div[^>]*>} $data </span> data
        regsub -all {<span[^>]*>} $data <span> data
        regsub -all {</span[^>]*>} $data </span> data
        regsub -all {<p [^>]*>} $data <p> data
        regsub -all {<ul [^>]*>} $data <ul> data
        regsub {<p> *編輯推薦 *</p>.*} $data "" data
        regsub {<span>看這些話題的相關文章：</span>.*} $data "" data
        regsub {<p> *【延伸閱讀】<br /></p>.*} $data "" data
        
        regsub -all "<span></span>" $data "" data
        regsub -all "</span><span>" $data "" data

        regsub -all {<h1 data-test-locator=.headline.>([^<]+)</h1>} $data "" data
        regsub -all {<button class=[^>]*>閱讀整篇文章<i></i></button>} $data "" data

        if {[regexp 今日新聞 $data]} {
            filter_article yahoohk $url
            return
        }

        set provider ""
        regexp {slk:([^;>]+);} $data dummy provider

        regsub -all {<a [^>]*title=\"[^\"]*((電郵)|(分享))\"[^>]*>} $data "" data
        regsub {.*<time class="caas-attr-meta-time" [^>]*>} $data "" data
        regsub {<section id="spot-im-comments">.*} $data "" data


        regsub -all {<span>} $data "" data
        regsub -all {</span>} $data "" data
        regsub {<h3>相關文章:.*} $data "" data
        regsub {熱門新聞</h2>.*} $data "" data
        regsub {<strong>更多資料</strong>.*} $data "" data

        regsub {</time>} $data "</time><p>" data
        if {"$data" == ""} {
            filter_article yahoohk $url
            return;
        }

        set data "${provider}&nbsp;\n$data"
        save_article yahoohk $title $url $data
    }
}
