# @rss-nt-adapter@

namespace eval 6park_forum_mil {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 1
        set h(lang)  zh
        set h(desc)  留园—网际谈兵
        set h(url)   http://site.6park.com/military
    }

    proc update_index {} {
        ::schedule_read {6park_forum::parse_index 6park_forum_mil} http://site.6park.com/military/ gb2312
    }
}
