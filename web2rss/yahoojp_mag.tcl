# @rss-nt-adapter@

namespace eval yahoojp_mag {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  jp
        set h(desc)  YahooMaga
        set h(url)   https://news.yahoo.co.jp/
        set h(out)   yjpmag
    }

    proc update_index {} {
        schedule_index https://news.yahoo.co.jp/ranking/access/magazine/it-science
        schedule_index https://news.yahoo.co.jp/ranking/access/magazine/domestic
        schedule_index https://news.yahoo.co.jp/ranking/access/magazine/world
        schedule_index https://news.yahoo.co.jp/ranking/access/magazine/business
        schedule_index https://news.yahoo.co.jp/ranking/access/magazine/life
    }

    proc schedule_index {index_url} {
        ::schedule_read [list yahoojp_mag::parse_index] $index_url
    }

    proc parse_index {index_url data} {
        foreach line [makelist $data href=] {
            if {[regexp {^\"([^\"]+article[?]a=[^\"]+)\"} $line dummy article_url] &&
                [regexp {<div class="newsFeed_item_title">([^<]+)</div>} $line dummy title]} {

                #puts =$article_url
                #puts .$title
                #puts ==[db_exists yahoojp_mag $article_url]==
                if {![db_exists yahoojp_mag $article_url]} {
                    ::schedule_read [list yahoojp_mag::parse_article [clock seconds]] $article_url
                    #return
                }
            }
        }
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list yahoojp_mag::parse_article [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        yahoojp::parse_article2 yahoojp_mag $pubdate $url $data
    }
}
