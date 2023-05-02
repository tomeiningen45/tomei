# @(disabled)rss-nt-adapter@

namespace eval 6park_forum_life {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 1
        set h(lang)  zh
        set h(desc)  留园—生活百态
        set h(url)   http://site.6park.com/life2
    }

    proc update_index {} {
        ::schedule_read {6park_forum::parse_index 6park_forum_life} http://site.6park.com/life2/ utf-8
    }
}
