# @rss-nt-adapter@

namespace eval hatelabo {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  jp
        set h(desc)  はてな
        set h(url)   https://anond.hatelabo.jp/archive
        set h(out)   hatelabo
    }

    proc update_index {} {
        schedule_index https://anond.hatelabo.jp/archive
    }

    proc schedule_index {index_url} {
        ::schedule_read [list hatelabo::parse_index] $index_url
    }

    proc parse_index {index_url data} {
        foreach line [makelist $data "<a href=\"/"] {
            if {[regexp {^([0-9]+)\">([^<]+)</a} $line dummy link title]} {
                set article_url https://anond.hatelabo.jp/$link
                if {![db_exists hatelabo $article_url]} {
                    ::schedule_read [list hatelabo::parse_article [clock seconds]] $article_url
                }
            }
        }
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list hatelabo::parse_article [clock seconds]] $url
    }
    
    proc parse_article {pubdate article_url data} {
        set title ""
        regexp {<title>([^<]+)</title>} $data dummy title
        if {"$title" != "" &&
            [regsub {.*id="title-below-ad">} $data "" data] &&
            [regsub {<p class="sectionfooter">.*} $data "" data]} {
            regsub -all {<a[^>]*>} $data "" data
            regsub -all {</a[^>]*>} $data "" data
            regsub -all {<div[^>]*>} $data "" data
            regsub -all {</div[^>]*>} $data "" data

            regsub -all {(<br[^>]*> *)+<p>} $data <p> data
            regsub -all {(<br[^>]*>)} $data <p> data 

            while {[regsub -all "<p *>\[\r\t\n \]*<p *>" $data <p> data]} {}

            regsub -all <p> $data "<p>\n\n&nbsp;" data

            regsub -all {</h[0-9][^>]*>} $data "" data
            regsub -all {<h[0-9][^>]*>} $data "\n\n<p>■" data

            regsub -all {[\u0001-\u0009]} $data "*" data
            save_article hatelabo $title $article_url $data $pubdate
        }
    }
}
