# @rss-nt-adapter@

namespace eval 6park {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 0
        set h(lang)  zh
        set h(desc)  留园
        set h(url)   https://www.vava8.com/
        set h(max_articles)  [::get_debug_opt DEBUG_MAX_ARTICLES  150]
        set h(max_downloads) [::get_debug_opt DEBUG_MAX_DOWNLOADS 25]
    }

    proc update_index {} {
        ::schedule_read 6park::parse_index https://www.vava8.com/index.php?app=index&act=api_list&limit=50&sort=latest&content_type=news utf-8
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {article_url} {
        ::schedule_read [list 6park::parse_toutiaoabc 12345 TITLE] $article_url utf-8
    }

    proc parse_index {index_url data} {
        set list {}

        foreach line [makelist $data {"id":}] {
            if {[regexp {^([0-9]+),} $line dummy id] &&
                [regexp {"title":"([^\"]+)"} $line dummy title]} {
                regsub -all {[$]} $title "\\\\u0024" title
                regsub -all {\[} $title "\\\\u005b" title
                regsub -all {\]} $title "\\\\u005d" title
                set title [eval set a \"$title\"]
                puts $title
                set url "https://www.vava8.com/index.php?app=index&act=view&id=$id"

                if {![info exists seen($url)]} {
                    set seen($url) 1
                    lappend list [list $url $title $id]
                }
            }
        }

        foreach item [lsort -dictionary $list] {
            # Get the oldest article first
            set article_url [lindex $item 0]
            set title       [lindex $item 1]
            set id          [lindex $item 2]
            if {![db_exists 6park $article_url]} {
                ::schedule_read [list 6park::parse_toutiaoabc $id $title] $article_url utf-8
                incr n
                if {$n > 10} {
                    # dont access the web site too heavily
                    break
                }
            }
        }
    }

    proc parse_toutiaoabc {id title url data} {
        global g


        set from ""
        if {[regexp {<meta name="author" content="([^>]+)">} $data dummy from]} {
            set from " | $from"
        }
        if {[regsub {^.*<div id="article-content">} $data "" data] &&
            [regsub {<div id="content-notice">.*} $data "" data]} {
            set data [string trim $data]
            regsub "^<p>" $data "" data
            append data "<p><p><p><p><p><img src='https://www.vava8.com/tpl/public/images/logo.png'>"
            save_article 6park $title$from $url $data
        }
    }
}
