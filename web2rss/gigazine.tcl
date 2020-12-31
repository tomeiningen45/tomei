# @rss-nt-adapter@

namespace eval gigazine {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  jp
        set h(desc)  GIGAZINE
        set h(url)   http://gigazine.net/
        set h(out)   gigazine
    }

    proc update_index {} {
        atom_update_index gigazine http://gigazine.net/index.php?/news/rss_2.0/
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list gigazine::parse_article gigazine [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
        regsub { - GIGAZINE} $title "" title

        if {[regsub {.*<!-- google_ad_section_start -->} $data "" data] || 
            [regsub {.*<h1 class="title">[^<]*</h1>} $data "" data]} {

            regsub {<!-- google_ad_section_end -->.*} $data "" data
            regsub {<div id="EndFooter">.*} $data "" data
            set data [noscript $data]

            regsub -all {<p class="preface">
<br />} $data <p> data

            save_article gigazine $title $url $data $pubdate
        }
    }
}
