# @rss-nt-lib@

namespace eval yahoojp {
    proc parse_article {which pubdate url data} {
        if {[regexp {<a href="([^\"]+)"[^>]*>続きを読む</a>} $data dummy link]} {
            ::schedule_read [list yahoojp::parse_article2 $which $pubdate] $link
        }
    }

    proc parse_article2 {which pubdate url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
        regsub { - Yahoo.*} $title "" title

        #puts $title
        #puts $url

        if {[regsub {.*<div class="article_body"[^>]*>} $data "" data]} {
            if {![regsub {【関連記事】.*} $data "<p>***" data]} {
                regsub {<style data-styled=.*} $data "" data
            }
            set data [noscript $data]
            regsub -all "\n" $data "<br>\n" data
            regsub {<div class=\"pagination.*} $data "\n <a href='$url'>続きを読む</a>" data
            save_article $which $title $url $data $pubdate
        }
    }
}
