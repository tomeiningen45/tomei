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
        #set h(redirect_images) 1
    }

    proc update_index {} {
        atom_update_index yahoojp_main https://news.yahoo.co.jp/rss/categories/domestic.xml
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list yahoojp_main::parse_article [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        parse_article2 $pubdate {} $url $url $data
    }

    # old_data = when parsing a series of pages, $old_data contains the pages that we have parsed so far
    proc parse_article2 {pubdate old_data orig_url url data} {
        regsub {[?]source=rss} $url "" url
        set title ""
        regexp {<title>([^<]+)</title>} $data dummy title
        regsub { - Yahoo.*} $title "" title
        if {"$title" != "" &&
            [regsub {.*<div class=.article_body [^>]+>} $data "" data] &&
            [regsub {<h3 [^>]+>[^<]*関連記事.*} $data "" data]} {
            regsub -all {<h[123]} $data "\n<h4" data
            regsub -all {</h[123]} $data "</h4" data
            regsub -all "\n\n　" $data "<p>" data
            regsub -all "。\n\n" $data "。<p>\n\n" data

            regsub -all {<p[^>]*>} $data "\n<p>" data
            regsub -all { class="[^">"]*"} $data " " data
            regsub -all { data-cl-params="[^">"]*"} $data " " data

            regsub -all {<div[^>]*>} $data "" data
            regsub -all {</div[^>]*>} $data "\n" data
            regsub -all {<svg[^>]*>} $data "" data
            regsub -all {</svg[^>]*>} $data "\n" data
            regsub -all {<path[^>]*>} $data "" data
            regsub -all {</path[^>]*>} $data "\n" data

            set next {<a href="([^<]+)"[^>]*>次ページ.*}
            if {[regexp $next $data dummy link]} {
                if {[regexp "^/" $link]} {
                    set link https://news.yahoo.co.jp$link
                }
                regsub $next $data "" data

                puts "yahoojp_main == following $link"
                ::schedule_read [list yahoojp_main::parse_article2 $pubdate "$old_data $data" $orig_url] $link
            } else {
                if {"$old_data" != ""} {
                    set title "【長文】$title"
                }

                regsub {<ul[^>]*><li[^>]*><a[^>]*>[^>]*<p>[^>]*前へ</a>.*} $data "" data
                append data "<p><p><img src='https://s.yimg.jp/c/icon/s/bsc/2.0/y120.png'>"
                save_article yahoojp_main $title $orig_url "$old_data $data" $pubdate
            }
        }
    }
}
