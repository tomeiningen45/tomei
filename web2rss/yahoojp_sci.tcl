# @(disabled)rss-nt-adapter@

namespace eval yahoojp_sci {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  jp
        set h(desc)  Yahoo科学
        set h(url)   https://news.yahoo.co.jp/
        set h(out)   yjpsci
    }

    proc update_index {} {
        atom_update_index yahoojp_sci http://news.yahoo.co.jp/pickup/science/rss.xml
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list yahoojp::parse_article yahoojp_sci [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        yahoojp::parse_article yahoojp_sci $pubdate $url $data
    }
}
