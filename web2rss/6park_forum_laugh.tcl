# @rss-nt-adapter@

namespace eval 6park_forum_laugh {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 1
        set h(lang)  zh
        set h(desc)  留园—笑口常开
        set h(url)   http://site.6park.com/enter1
    }

    proc update_index {} {
        ::schedule_read {6park_forum::parse_index 6park_forum_laugh} http://site.6park.com/enter1/ gb2312
    }
}
