# @rss-nt-adapter@

namespace eval dqn {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  jp
        set h(desc)  痛いニュース(ﾉ∀`)
        set h(url)   http://blog.livedoor.jp/dqnplus/
        set h(out)   dqn
    }

    proc update_index {} {
        rdf_update_index dqn http://blog.livedoor.jp/dqnplus/index.rdf euc-jp
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list bleacher::parse_article [clock seconds]] $url
    }

    proc parse_article {pubdate url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
 
        regsub "痛いニュース\[^:\]*: " $title "" title
        regsub " - ライブドアブログ" $title "" title

        set moto ""
        if {[regexp "元スレ.(http\[^< \n\]+)" $data dummy moto]} {
            set moto "元スレ: <a href='$moto'>$moto</a><p>\n\n"
        }

        regsub {.*<div class="main entry-content">} $data "" data
        regsub {<div class=posted>.*} $data "" data

        regsub -all {<div class="t_h"[^>]*>} $data "\n<br>" data

        regsub -all {<div[^>]*>} $data "\n" data
        regsub -all {</div[^>]*>} $data "" data

        regsub -all {<span style=[^>]*>[^<]+</span> <span style=[^>]*> 202[0-9]/[0-9]+/[0-9]+[^<]*ID:[^<]*</span>} $data "" data

        regsub -nocase -all {<span[^>]*>} $data "\n" data
        regsub -nocase -all {</span[^>]*>} $data "" data

        set data "$moto$data"
        save_article dqn $title $url $data $pubdate
    }
}
