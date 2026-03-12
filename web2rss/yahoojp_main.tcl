# @rss-nt-adapter@

namespace eval yahoojp_main {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  jp
        set h(desc)  Yahoo主要
        set h(url)   https://news.yahoo.co.jp/
        set h(out)   yjpmain
        set h(redirect_images) 1
    }

    proc update_index {} {
        atom_update_index yahoojp_main https://news.yahoo.co.jp/rss/categories/domestic.xml
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list yahoojp::parse_article yahoojp_main [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        regsub {[?]source=rss} $url "" url
        set title ""
        regexp {<title>([^<]+)</title>} $data dummy title
        regsub { - Yahoo.*} $title "" title
        if {"$title" != "" &&
            [regsub {.*<div class=.article_body [^>]+>} $data "" data] &&
            [regsub {<h3 [^>]+>[^<]*関連記事.*} $data "" data]} {
            append data "<p><p><img src='https://s.yimg.jp/c/icon/s/bsc/2.0/y120.png'>"
            save_article yahoojp_main $title $url $data $pubdate
        }
    }
}
