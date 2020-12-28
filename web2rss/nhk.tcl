# @rss-nt-adapter@

namespace eval nhk {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  jp
        set h(desc)  NHK
        set h(url)   https://www3.nhk.or.jp/
        set h(out)   nhk
    }

    proc update_index {} {
        atom_update_index nhk https://www3.nhk.or.jp/rss/news/cat0.xml
        atom_update_index nhk https://www3.nhk.or.jp/rss/news/cat5.xml
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list nhk::parse_article nhk [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
        regsub { [|] .*} $title "" title

        set video ""
        regexp {<iframe class="video-player-fixed"[^>]*></iframe>} $data video
        regsub {src=\"/} $video "src=\"https://www3.nhk.or.jp/" video

        set img ""
        if {"$video" == ""} {
            regexp {<img class="lazy" [^>]*>} $data img
        }

        regsub {.*<div class="content--detail-body">} $data "" data
        regsub {<article class="module module--detail-related">.*} $data "" data
        regsub {<article class="module">.*} $data "" data

        if {"$video" != ""} {
            set data "<span class=\"webrss-video\">$video</span> <p>\n$data"
        }
        if {"$img" != ""} {
            set data "<span class=\"webrss-headimage\">$img</span> <p>\n$data"
        }

        regsub -all {<img class="lazy" src="[^\"]*"} $data "<img " data
        regsub -all {data-src=\"/} $data "src=\"https://www3.nhk.or.jp/" data
        regsub -all {<p class="button"><i class="i-arrow is-down_g"></i>続きを読む</p>} $data "<p>" data

        save_article nhk $title $url $data $pubdate
    }
}
