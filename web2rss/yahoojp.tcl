# @rss-nt-lib@

namespace eval yahoojp {
    # This is called by yahoojp_main and yahoojp_sci, which use the "pickup" format
    # in <data>. We need to get the article_url for the real content of the article
    proc parse_article {which pubdate pickup_url data} {
        if {[regexp {<a href="([^\"]+)"[^>]*>続きを読む</a>} $data dummy article_url]} {
            if {![db_exists $which $article_url]} {
                ::schedule_read [list yahoojp::parse_article2 $which $pubdate] $article_url
            }
        }
    }

    proc parse_article2 {which pubdate article_url data} {
        parse_article3 $which $pubdate $article_url {} $article_url $data
    }

    proc parse_article3 {which pubdate article_url previous_pages page_url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
        regsub { - Yahoo.*} $title "" title

        #puts $title
        #puts $page_url

        if {[regsub {.*<div class="article_body"[^>]*>} $data "" data]} {
            set next ""
            regexp {<a href="(/articles/[^\"]+[?]page=[0-9]+)"[^>]*>次へ} $data dummy next

            if {![regsub {【関連記事】.*} $data "<p>***" data]} {
                regsub {<style data-styled=.*} $data "" data
            }

            regsub -all {<a href=[^>]*:related;[^>]*>[^<]*</a>} $data "" data
            regsub -all {<footer class.*} $data "" data

            set data [noscript $data]
            set data [nostyle $data]
            regsub -all "\n" $data "<br>\n" data

            regsub {<div class=\"pagination.*} $data "" data
            regsub -all {<a href=[^>]*>次ページは：[^<]*</a>} $data "" data
            regsub -all {<div class=[^>]*>} $data "<div>" data
            regsub -all { data-ylk=\"[^\"]+\"} $data " " data
            regsub -all { class=\"[^\"]+\"} $data " " data

            while {[regsub -all "<br>\[\r\t\n \]*<br>\[\r\t\n \]*<br>" $data "<br><br>" data]} {}
            regsub -all "<br>\n*<br>" $data "</p><p>" data
            regsub -all {<h[1-9][^>]*>([^<]*)</h[1-9]>} $data "\n<p><b>●\\1</b></p>\n<p>" data

            while {[regsub -all "<p *>\[\r\t\n \]*<p *>" $data <p> data]} {}

            regsub -all "<p>\n*\[　 \]*" $data "<p>\n　" data

            regsub -all {<div[^>]*>} $data "" data
            regsub -all {</div[^>]*>} $data "" data

            set data "$previous_pages $data"
            if {"$next" != ""} {
                set next_url https://news.yahoo.co.jp$next
                ::schedule_read [list yahoojp::parse_article3 $which $pubdate $article_url $data] $next_url
            } else {
                if 0 {
                    # $text is for easy printing.
                    set text $data
                    regsub -all <img $text "<xximg" text
                    append data "\n\n\n<p><br>=================== Print <p><br><p><br><p><br><p><br><p><br></h1></h2></h3></h4></h5></h6></b>\n\n\n$text"
                }
                save_article $which $title $article_url $data $pubdate
            }
        }
    }
}
